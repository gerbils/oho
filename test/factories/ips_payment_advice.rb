FactoryBot.define do
  factory :ips_payment_advice do
     pay_cycle { "2025-04" }
      pay_cycle_seq_number { 1 }
      payment_reference { "PAYREF12345" }
      payment_date { "2005-05-31" }
      total_amount { 1000.00 }
      status { IpsPaymentAdvice::STATUS_UPLOADED }
  end
end
