# == Schema Information
#
# Table name: woo_line_items
#
#  id                           :bigint           not null, primary key
#  is_ri                        :boolean
#  amount                       :decimal(10, 2)
#  qty                          :integer
#  sku                          :string(30)
#  woo_modified_dtm             :datetime
#  created_at                   :datetime         not null
#  updated_at                   :datetime         not null
#  import_to_royalties_batch_id :integer
#  woo_li_or_ri_id              :integer
#  woo_order_id                 :integer

class WooLineItem < ApplicationRecord


end
