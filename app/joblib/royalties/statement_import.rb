# Import the data from a given LP upload
clsss Royalties::StatementImport

  # State = Struct.new("State", :statement, :free_units, :paid_units, :return_units,
  #                     :paid_amount, :return_amount, :when, :errors)

  def initialize(statement)
      @errors        = []
      @statement     = statement
      @free_units    = 0
      @paid_units    = 0
      @return_units  = 0
      @paid_amount   = BigDecimal("0.00")
      @return_amount = BigDecimal("0.00")
      @when          = Time.now
  end

  def import
      ri_values = create_new_royalty_lines
      if ri_values.empty?
        @errors << "No royalty items found"
      else
        commit(ri_values)
      end

    if @errors.empty?
      { status: :ok, totals: state }
    else
      @statement.set_import_status!(IpsStatement::STATUS_FAILED_IMPORT, message: @errors.join(", "))
      { status: :error, message: state.errors.join("\n") }
    end
  end

  private

  def commit(ri_values)
    RoyaltyItem.connection.transaction do
      RoyaltyItem.insert_all!(ri_values)
      @statement.set_import_status!(IpsStatement::STATUS_IMPORTED, imported_at: @when, message: nil)
    end
  rescue => e
    raise if ENV["debug"]
    @errors << "Error importing royalty items: #{e.message}"
  end

  def create_new_royalty_lines()
    ris = RiList.new
    @statement.statement_lines.each do |proto_ri|
      ris.add(proto_ri)
    end
    ris.values
  rescue => e
    raise if ENV["debug"]
    state.errors << "Error creating royalty lines: #{e.message}"
    []
  end

  class RiList
    def initialize
      @ris = {}
    end

    def values
      @ris.values
    end

    def add(proto_ri)
      sku_id = proto_ri[:sku_id]
      if @ris[sku_id]
        @ris[sku_id][:paid_units]    += proto_ri[:paid_units]
        @ris[sku_id][:paid_amount]   += proto_ri[:paid_amount]
        @ris[sku_id][:free_units]    += proto_ri[:free_units]
        @ris[sku_id][:return_units]  += proto_ri[:return_units]
        @ris[sku_id][:return_amount] += proto_ri[:return_amount]
      else
        @ris[sku_id] = proto_ri
      end
    end
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
