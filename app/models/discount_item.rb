# == Schema Information
#
# Table name: discount_items
#
#  id           :integer          not null, primary key
#  amount       :decimal(8, 2)    default(0.0)
#  name         :string(255)
#  quantity     :integer          default(1)
#  total_amount :decimal(8, 2)    default(0.0)
#  coupon_id    :integer
#  discount_id  :integer
#  order_id     :integer          not null
#
# Indexes
#
#  fk_discount_items_coupon_id                     (coupon_id)
#  fk_discount_items_discount_id                   (discount_id)
#  fk_discount_items_order_id                      (order_id)
#  index_discount_items_on_order_id_and_coupon_id  (order_id,coupon_id) UNIQUE
#
# Foreign Keys
#
#  fk_discount_items_coupon_id    (coupon_id => coupons.id)
#  fk_discount_items_discount_id  (discount_id => discounts.id)
#  fk_discount_items_order_id     (order_id => orders.id)
#
class DiscountItem < LegacyRecord

  belongs_to :order
  belongs_to :discount
  belongs_to :coupon

  def discount?
    self.discount
  end

end
