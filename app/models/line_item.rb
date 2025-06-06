# == Schema Information
#
# Table name: line_items
#
#  id                    :integer          not null, primary key
#  download_ready        :boolean          default(FALSE)
#  download_token        :string(255)
#  first_shipped         :datetime
#  fulfill_in_progress   :string(255)
#  gateway_fee           :decimal(8, 2)    default(0.0)
#  last_shipped          :datetime
#  last_shipped_from     :string(255)
#  last_shipped_method   :string(255)
#  name                  :string(255)      default("")
#  new_version_available :boolean          default(FALSE)
#  quantity              :integer          default(1)
#  ship_count            :integer          default(0)
#  ship_in_progress      :integer          default(0)
#  sold_at_price         :decimal(8, 2)    default(0.0)
#  tracking_number       :string(255)
#  unit_price            :decimal(8, 2)    not null
#  weight                :integer          default(0)
#  order_id              :integer          not null
#  sku_id                :integer          not null
#
# Indexes
#
#  fk_line_items_order_id                (order_id)
#  fk_line_items_sku_id                  (sku_id)
#  index_line_items_on_download_token    (download_token)
#  index_line_items_on_last_shipped      (last_shipped)
#  index_line_items_on_ship_in_progress  (ship_in_progress)
#
# Foreign Keys
#
#  fk_line_items_order_id  (order_id => orders.id)
#  fk_line_items_sku_id    (sku_id => skus.id)
#
class LineItem < LegacyRecord
    belongs_to :sku
    belongs_to :order

  def total_price
    self.unit_price * self.quantity
  end

end

