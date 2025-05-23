class LineItem < LegacyRecord
    belongs_to :sku
    belongs_to :order

  def total_price
    self.unit_price * self.quantity
  end

end

