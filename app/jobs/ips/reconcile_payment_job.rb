class Ips::ReconcilePaymentJob < ApplicationJob
  queue_as :default

  def perform(payment_id)
    logger.info("starting IPS reconcile payment job")
    payment = IpsPaymentAdvice.find(payment_id)
    OhoError.clear_errors(payment)

    unless payment.status == IpsPaymentAdvice::STATUS_UPLOADED
      logger.error("payment #{payment.id} status #{payment.status} and cannot be reconciled yet")
      payment.update!(status_message: "payment is not ready to be reconciled (status is #{payment.status})")
      return
    end

    begin

      Royalties::Ips::ReconcilePayments.handle(payment)

    rescue => e
      raise if ENV['debug']
      Rails.logger.error("Error handling reconciliation: #{e.message}")
      OhoError.create(
        owner: payment,
        label: "Error reconciling payment #{payment.paymnt_date}",
        message: e.message,
        level: OhoError::ERROR
      )
      payment.update!(status: Ipspayment::STATUS_FAILED_RECONCILE, status_message: e.message)
    end
    logger.info("finishing IPS reconcile payment job")
  end
end
