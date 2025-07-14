# == Schema Information
#
# Table name: ips_detail_lines
#
#  id                      :bigint           not null, primary key
#  amount                  :decimal(10, 4)
#  content_type            :string(255)
#  description             :string(255)
#  ean                     :string(255)
#  json                    :json
#  quantity                :integer
#  title                   :string(255)
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  ips_statement_detail_id :bigint
#  sku_id                  :integer
#
# Indexes
#
#  index_ips_detail_lines_on_ips_statement_detail_id  (ips_statement_detail_id)
#
# Foreign Keys
#
#  fk_rails_...  (ips_statement_detail_id => ips_statement_details.id)
#
class IpsDetailLine < ApplicationRecord
  self.inheritance_column = :_none   # disable STI  TODO: needed?

  belongs_to :ips_statement_detail, optional: true, counter_cache: true
  belongs_to :sku

  validates(
        :ips_statement_detail_id,
        :content_type,
        :description,
        :quantity,
        :amount,
        :json,
       presence: true)


  def from_json()
    @parsed_json ||= JSON.parse(json)
  end

  def json=(obj)
    @parsed_json = obj
    super(obj)
  end

end
