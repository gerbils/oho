# == Schema Information
#
# Table name: payout_transactions
#
#  id                         :integer          not null, primary key
#  api_message                :text(16777215)
#  batch_size                 :integer
#  gateway_transaction_ident  :string(255)
#  provider_type              :string(255)
#  response_message           :text(16777215)
#  status                     :string(255)
#  transaction_type           :string(255)
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#  pay_authors_transaction_id :integer
#
class PayoutTransaction < LegacyRecord
  PROVIDER_TYPE_PAYPAL = "paypal"
  PROVIDER_TYPE_DWOLLA = "dwolla"
  PROVIDER_TYPE_CHECK = "check"

  TRANSACTION_TYPE_BATCH = "batch"
  TRANSACTION_TYPE_SINGLE = "single"

  STATUS_STARTED = "started"
  STATUS_SENT = "sent"
  STATUS_COMPLETED = "complete"
  STATUS_FAILED = "failed"

  TRAN_IDENT_FAIL = "FAIL"
  TRAN_IDENT_FILLER = "FILLER"

end
