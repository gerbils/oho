ProtoRoyaltyLine = Struct.new(
  "ProtoRoyaltyLine",
      :sku_id,        # sku_id,
      :item_type,     # RoyaltyItem::LP_TYPE,
      :description,   # "LP Sales #{state.statement.report_period}",
      :free_units,    # 0,
      :paid_units,    # 1,
      :paid_amount,   # BigDecimal("0.00"),
      :return_units,  # 0,
      :return_amount, # 0,
      :book_basis,    # 0,
      :date,          # state.when,
      :applies_to,    # RoyaltyItem::APPLIES_TO_BOTH,
      :source_type,   # "LP",
      :source_id,     # state.statement.id,
 ) do
  def merge(other)
    self.paid_units += other.paid_units
    self.paid_amount += other.paid_amount
    self.free_units += other.free_units
    self.return_units += other.return_units
    self.return_amount += other.return_amount
  end
end

