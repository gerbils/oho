module PoorMansFactoryBot
def upload_wrapper!
  uw = UploadWrapper.new
  temp_file = Tempfile.new(['test_upload', '.txt'])
  temp_file.write("This is a test file.")
  temp_file.rewind
  uw.file.attach(
    io: temp_file,
    filename: 'some-temp-file.txt',
    content_type: 'text/plain'
  )
  temp_file.unlink
  uw
end

IS_DEFAULTS = {
    gross_sales_total:    0 ,
    gross_returns_total:  0 ,
    net_sales:            0 ,
    total_chargebacks:    0 ,
    total_expenses:       0 ,
    net_client_earnings:  0 ,
    month_ending:         Date.new(2025, 3, 31) ,
    status:               IpsStatement::STATUS_UPLOADED ,
    upload_wrapper:       nil ,
}
def ips_statement!(params)
  result = IpsStatement.new(IS_DEFAULTS.merge(params))
  result.upload_wrapper ||= upload_wrapper!
  result
end


ISD_DEFAULTS = {
    section:           IpsStatementDetail::SECTION_EXPENSE ,
    subsection:        "subsection" ,
    detail:            "detail" ,
    month_due:         Date.new(2025, 4, 1) ,
    basis_for_charge:  0 ,
    factor_or_rate:    0 ,
    due_this_month:    0 ,
}
def ips_statement_detail!(params)
  result = IpsStatementDetail.new(ISD_DEFAULTS.merge(params))
  result.upload_wrapper = upload_wrapper! unless result.upload_wrapper
  result
end

IDL_DEFAULTS = {
      sku_id: nil,
      ean: nil,
      title: nil,
      content_type: nil,
      description: nil,
      quantity: nil,
      amount: nil,
      json: { dummy: 99 }
}
def ips_detail_line!(params)
  sku = params[:sku]
  params[:sku] = case sku
  when Sku
    sku
  when Symbol
    sku = skus(sku)
  when nil
    nil
  else
    fail "Expecting Sku, symbol or nil for Sku"
  end
  result = IpsDetailLine.new(IDL_DEFAULTS.merge(params))
  result
end


IPA_DEFAULTS = {
     pay_cycle:  "2025-04" ,
      pay_cycle_seq_number:  1 ,
      payment_reference:  "PAYREF12345" ,
      payment_date:  "2005-05-31" ,
      total_amount:  1000.00 ,
      status:  IpsPaymentAdvice::STATUS_UPLOADED ,
}
def ips_payment_advice!(params = {})
  result = IpsPaymentAdvice.new(IPA_DEFAULTS.merge(params))
  result.upload_wrapper = upload_wrapper! unless result.upload_wrapper
  result
end

IPAL_DEFAULTS = {
    invoice_number:  "INV12345" ,
    invoice_date:    "2025-04-01" ,
    voucher_id:      "VOUCHER123" ,
    paid_amount:     500.00 ,
    discount_taken:  0.00 ,
    gross_amount:    500.00,
    status:  IpsPaymentAdviceLine::STATUS_UNRECONCILED ,
}
def ips_payment_advice_line!(params = {})
  result = IpsPaymentAdviceLine.new(IPAL_DEFAULTS.merge(params))
  result.ips_payment_advice ||= ips_payment_advice!
  result
end

end
