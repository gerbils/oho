# Import the data from a given LP upload
module Royalties::Ips::ImportHandler
  extend self

  State = Struct.new("State", :upload, :free_units, :paid_units, :return_units,
                      :paid_amount, :return_amount, :when, :errors)

  def handle_import(upload)
    import(create_state(upload))
  end

  private

  def create_state(upload)
    State.new(
      upload: upload,
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
      state.upload.status = Upload::STATUS_IMPORTED
      state.upload.imported_at = state.when
      state.upload.error_msg = nil
      state.upload.save!
      { status: :ok, totals: state }
    else
      state.upload.status = Upload::STATUS_FAILED_IMPORT
      state.upload.error_msg = state.errors.join(", ")
      state.upload.save!
      { status: :error, message: state.errors.join("\n") }
    end
  end

  private

  def commit(state, ri_values)
    RoyaltyItem.connection.transaction do
      RoyaltyItem.insert_all!(ri_values)
      state.upload.imported_at = state.when
      state.upload.status = Upload::STATUS_IMPORTED
      state.upload.save!
    end
  rescue => e
    state.errors << "Error committing royalty items: #{e.message}"
  end

  def create_new_royalty_lines(state)
    ris = {}
    state.upload.royalty_raw_lp_data.each do |raw|
      sku_id = raw.sku_id || fail("Mising sku id in #{raw.inspect}")
      ri = (ris[sku_id] ||= proto_ri(state, sku_id))
      ri[:paid_amount] += raw.commission_earned
    end
    ris.values
  rescue => e
    state.errors << "Error creating royalty lines: #{e.message}"
    []
  end

  def proto_ri(state, sku_id)
    {
      sku_id: sku_id,
      item_type: RoyaltyItem::LP_TYPE,
      description: "LP Sales #{state.upload.report_period}",
      free_units: 0,
      paid_units: 1,
      paid_amount: BigDecimal("0.00"),
      return_units: 0,
      return_amount: 0,
      book_basis: 0,
      date: state.when,
      applies_to: RoyaltyItem::APPLIES_TO_BOTH,
      source_type: "LP",
      source_id: state.upload.id,
    }
  end
end
