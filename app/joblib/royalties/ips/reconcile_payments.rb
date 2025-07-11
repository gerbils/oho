
module Royalties::Ips; end
module Royalties::Ips::ReconcilePayments
  extend self

  def handle(payment_advice)
    payment_advice.clear_oho_errors
#TODO: check status to make sure we don't do this twice
    payment_advice.ips_payment_advice_lines.each do |line|
      reconcile_line(line) unless line.reconciled?
    end
  end


  # the advice line has a date, a description, and a paid_amount.
  # We use the date and description to find the matching statement detail line,
  # and verify the amount is the same. If so, we associate the detail line
  # with the payment advice line, marking both as having been reconciled.
  def reconcile_line(line)
    match = IpsStatementDetail.match_with_payment(line.invoice_date, line.invoice_number, line.paid_amount)
    case match.length

    when 0 # no match found, log an error
      OhoError.create(
        owner: line,
        label: "No matching statement detail line found",
        message: "No matching statement detail line found for invoice #{line.invoice_number} on #{line.invoice_date} with amount #{line.paid_amount}",
        level: OhoError::ERROR
      )
      line.status = IpsPaymentAdviceLine::STATUS_UNRECONCILED

    when 1 # one match found, associate it with the payment advice line
      detail_line = match.first
      line.ips_statement_detail = detail_line
      line.status = IpsPaymentAdviceLine::STATUS_RECONCILED
      detail_line.reconciled = true
      detail_line.save!

    else # multiple matches found, log an error
      OhoError.create(
        owner: line,
        label: "Multiple matching statement detail lines found",
        message: "Multiple matching statement detail lines found for invoice #{line.invoice_number} on #{line.invoice_date} with amount #{line.paid_amount}",
        level: OhoError::ERROR
      )
      line.status = IpsPaymentAdviceLine::STATUS_TOO_MANY_MATCHES
    end
    line.save!
  end
end
