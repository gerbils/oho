# == Schema Information
#
# Table name: orders
#
#  id                            :integer          not null, primary key
#  address                       :string(255)
#  address2                      :string(255)
#  city                          :string(255)
#  company                       :string(255)
#  country                       :string(255)
#  discount_total                :decimal(8, 2)    default(0.0)
#  email                         :string(255)
#  gift_message                  :text(65535)
#  grand_total                   :decimal(8, 2)    default(0.0)
#  how_heard                     :string(255)
#  how_heard_other               :string(255)
#  imported_into_royalties_at    :datetime
#  ip_hostname                   :string(255)
#  is_tax_exempt                 :boolean          default(FALSE)
#  most_recent_shopify_signature :string(32)
#  name                          :string(255)
#  number                        :string(30)
#  order_origin                  :string(255)
#  pay_detail                    :string(255)
#  pay_notes                     :string(255)
#  pay_type                      :integer
#  paypal_authorization          :string(255)
#  paypal_token                  :string(255)
#  pdf_stamp_name                :string(255)
#  phone                         :string(255)
#  po_num                        :text(65535)
#  product_total                 :decimal(8, 2)    default(0.0)
#  receipt_details               :text(65535)
#  ship_address                  :string(255)
#  ship_address2                 :string(255)
#  ship_city                     :string(255)
#  ship_company                  :string(255)
#  ship_country                  :string(255)
#  ship_email                    :string(255)
#  ship_name                     :string(255)
#  ship_phone                    :string(255)
#  ship_state                    :string(255)
#  ship_type                     :string(255)
#  ship_zip                      :string(255)
#  shipping_instructions         :string(255)
#  shipping_total                :decimal(8, 2)    default(0.0)
#  state                         :string(255)
#  tax_total                     :decimal(8, 2)    default(0.0)
#  token                         :string(255)
#  type                          :string(255)
#  weight_total                  :integer          default(0)
#  when_billed                   :datetime
#  zip                           :string(255)
#  created_at                    :datetime
#  updated_at                    :datetime
#  auth_trans_id                 :string(20)       default("0")
#  braintree_txn_id              :integer
#  buyer_id                      :integer
#  dwolla_checkout_id            :string(255)
#  owner_id                      :integer
#  paypal_payer_id               :string(255)
#  shopify_ingest_batch_id       :integer
#
# Indexes
#
#  fk_orders_braintree_txn_id            (braintree_txn_id)
#  fk_orders_buyer_id                    (buyer_id)
#  fk_orders_owner_id                    (owner_id)
#  index_orders_on_dwolla_checkout_id    (dwolla_checkout_id) UNIQUE
#  index_orders_on_email                 (email)
#  index_orders_on_number                (number)
#  index_orders_on_ship_email            (ship_email)
#  index_orders_on_token                 (token) UNIQUE
#  index_orders_on_type                  (type)
#  index_orders_on_type_and_when_billed  (type,when_billed)
#  orders_ingest_shopify_batch_id_idx    (shopify_ingest_batch_id)
#
# Foreign Keys
#
#  fk_orders_braintree_txn_id  (braintree_txn_id => braintree_txns.id)
#  fk_orders_buyer_id          (buyer_id => users.id)
#  fk_orders_owner_id          (owner_id => users.id)
#
 class DeactivatedOrder < Order

 end
