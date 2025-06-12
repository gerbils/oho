class IpsDetailLine < ApplicationRecord
  self.inheritance_column = :_none   # disable STI

  belongs_to :ips_statement_detail, optional: true, counter_cache: true
  belongs_to :upload_wrapper
  belongs_to :sku

  validates(
        :ips_statement_detail_id,
        :sku_id,
        :content_type,
        :description,
        :quantity,
        :amount,
        :json,
       presence: true)

end
