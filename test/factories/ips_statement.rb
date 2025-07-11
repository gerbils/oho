
FactoryBot.define do
  factory :ips_statement do
    gross_sales_total   { 0 }
    gross_returns_total { 0 }
    net_sales           { 0 }
    total_chargebacks   { 0 }
    total_expenses      { 0 }
    net_client_earnings { 0 }
    status              { IpsStatement::STATUS_UPLOADED }
    upload_wrapper      { nil }
  end
end
