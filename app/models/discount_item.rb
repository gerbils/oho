class DiscountItem < LegacyRecord

  belongs_to :order
  belongs_to :discount
  belongs_to :coupon

  def discount?
    self.discount
  end

end
