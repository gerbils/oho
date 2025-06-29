class IpsDetailLine < ApplicationRecord
  self.inheritance_column = :_none   # disable STI  TODO: needed?

  belongs_to :ips_statement_detail, optional: true, counter_cache: true

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
