# Import the data from a given LP upload
module Royalties::Lp::ImportHandler
  extend self

  State = Struct.new("State", :statement, :free_units, :paid_units, :return_units,
                      :paid_amount, :return_amount, :when, :errors)

  def handle(statement)
    import(create_state(statement))
  end

  private

  def create_state(statement)
    State.new(
      statement: statement,
      free_units: 0,
      paid_units: 0,
      return_units: 0,
      paid_amount: BigDecimal("0.00"),
      return_amount: BigDecimal("0.00"),
      when: Time.now,
      errors: [],
    )
  end

  def import(state)
      ri_values = create_new_royalty_lines(state)
      if ri_values.empty?
        state.errors << "No royalty items found"
      else
        commit(state, ri_values)
      end

    if state.errors.empty?
      state.statement.status = LpStatement::STATUS_IMPORTED
      state.statement.imported_at = state.when
      state.statement.status_message = nil
      state.statement.save!
      { status: :ok, totals: state }
    else
      state.statement.status = LpStatement::STATUS_FAILED_IMPORT
      state.statement.status_message = state.errors.join(", ")
      state.statement.save!
      { status: :error, message: state.errors.join("\n") }
    end
  end

  private

  def commit(state, ri_values)
    RoyaltyItem.connection.transaction do
      RoyaltyItem.insert_all!(ri_values)
      state.statement.imported_at = state.when
      state.statement.status = LpStatement::STATUS_IMPORTED
      state.statement.save!
    end
  rescue => e
    raise if ENV["debug"]
    state.errors << "Error importing LP royalty items: #{e.message}"
  end

  def create_new_royalty_lines(state)
    ris = {}
    state.statement.lp_statement_lines.each do |line|
      sku_id = line.sku_id || fail("Mising sku id in #{line.inspect}")
      ri = (ris[sku_id] ||= proto_ri(state, sku_id))
      ri[:paid_amount] += line.commission_earned
    end
    ris.values
  rescue => e
    raise if ENV["debug"]
    state.errors << "Error creating royalty lines: #{e.message}"
    []
  end

  def proto_ri(state, sku_id)
    {
      sku_id: sku_id,
      item_type: RoyaltyItem::LP_TYPE,
      description: "LP Sales #{state.statement.report_period}",
      free_units: 0,
      paid_units: 1,
      paid_amount: BigDecimal("0.00"),
      return_units: 0,
      return_amount: 0,
      book_basis: 0,
      date: state.when,
      applies_to: RoyaltyItem::APPLIES_TO_BOTH,
      source_type: "LP",
      source_id: state.statement.id,
    }
  end
end
