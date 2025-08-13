class IpsReconciliation < ApplicationRecord
  belongs_to :ips_statement_detail
  belongs_to :ips_payment_advice_line
end

