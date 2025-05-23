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
