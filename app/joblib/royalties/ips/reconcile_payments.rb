
module Royalties::Ips; end
module Royalties::Ips::ReconcilePayments
  extend self

  def handle(payment_advice)
    payment_advice.clear_oho_errors
    #TODO: check status to make sure we don't do this twice
    payment_advice.ips_payment_advice_lines.each do |line|
      reconcile_line(line) unless line.reconciled?
    end

    if payment_advice.all_reconciled?
      payment_advice.update!(status: IpsPaymentAdvice::STATUS_RECONCILED, status_message: nil)
    else
      payment_advice.update!(status: IpsPaymentAdvice::STATUS_PARTIALLY_RECONCILED, status_message: "Some lines could not be reconciled")
    end
  end


  # the advice line has a date, a description, and a paid_amount.
  # We use the date and description to find the matching statement detail line,
  # and verify the amount is the same. If so, we associate the detail line
  # with the payment advice line, marking both as having been reconciled.
  def reconcile_line(line)
    match = IpsStatementDetail.match_with_payment(line.invoice_date, line.invoice_number, line.paid_amount)
    case match.length

    when 0 # no match found, might need to combine two details
      matches = IpsStatementDetail.match_with_combinations(line.invoice_date, line.invoice_number, line.paid_amount)
      case matches.length
      when 0 # no matching statement detail line found, log an error
        flag_error(line, "No matching statement detail lines found", IpsPaymentAdviceLine::STATUS_UNRECONCILED)
      when 1
        mark_as_reconciled(line, matches.first)
      else
        flag_error(line, "Multiple matching combinations of detail lines found", IpsPaymentAdviceLine::STATUS_TOO_MANY_MATCHES)
      end

    when 1 # one match found, associate it with the payment advice line
      detail_line = match.first
      mark_as_reconciled(line, [detail_line])

    else # multiple matches found, log an error
      flag_error(line, "Multiple matching statement detail line found", IpsPaymentAdviceLine::STATUS_TOO_MANY_MATCHES)
    end

    line.save!
  end

  def flag_error(line, message, status)
      OhoError.create(
        owner: line,
        label: message,
        message: "#{message} for invoice #{line.invoice_number} on #{line.invoice_date} with amount #{line.paid_amount}",
        level: OhoError::ERROR
      )
      line.status = status
  end

  def mark_as_reconciled(advice, detail_lines)
    IpsPaymentAdviceLine.transaction do
      detail_lines.each do |detail_line|
        advice.ips_statement_details << detail_line
        detail_line.reconciled = true
        detail_line.save!
      end
      advice.status = IpsPaymentAdviceLine::STATUS_RECONCILED
    end
  end
end
