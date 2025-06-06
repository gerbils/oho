# == Schema Information
#
# Table name: ips_revenue_lines
#
#  id                        :bigint           not null, primary key
#  brand_category            :string(255)
#  customer_discount         :decimal(6, 5)
#  customer_po_or_claim_no   :string(255)
#  date                      :string(255)
#  ean                       :string(255)
#  format                    :string(255)
#  headquarter               :string(255)
#  hq_account_no             :string(255)
#  imprint                   :string(255)
#  invoice_or_credit_memo_no :string(255)
#  list_amount               :decimal(8, 2)
#  pub_alpha                 :string(255)
#  qty                       :integer
#  shipping_location         :string(255)
#  sl_city                   :string(255)
#  sl_state                  :string(255)
#  title                     :string(255)
#  type                      :string(255)
#  value                     :decimal(8, 2)
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  ips_statement_details_id  :bigint
#  sku_id                    :integer
#  upload_wrapper_id         :bigint           not null
#
# Indexes
#
#  index_ips_revenue_lines_on_ips_statement_details_id  (ips_statement_details_id)
#  index_ips_revenue_lines_on_upload_wrapper_id         (upload_wrapper_id)
#
# Foreign Keys
#
#  fk_rails_...  (ips_statement_details_id => ips_statement_details.id)
#  fk_rails_...  (upload_wrapper_id => upload_wrappers.id)
#
class IpsRevenueLine < ApplicationRecord
  belongs_to :ips_statement_detail, optional: true
  belongs_to :upload_wrapper
end

