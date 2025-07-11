FactoryBot.define do
  factory :ips_payment_advice_line do
    association    :ips_payment_advice
    invoice_number { "INV12345" }
    invoice_date   { "2025-04-01" }
    voucher_id     { "VOUCHER123" }
    paid_amount    { 500.00 }
    discount_taken { 0.00 }
    gross_amount   { paid_amount + discount_taken }
    status { IpsPaymentAdviceLine::STATUS_UNRECONCILED }
  end
end

