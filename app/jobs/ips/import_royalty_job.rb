class Ips::ImportRoyaltyJob < ApplicationJob
  queue_as :default

  def perform(payment_id)
    logger.info("starting IPS import job")
    payment = IpsPaymentAdvice.find(payment_id)
    OhoError.clear_errors(payment)

    unless payment.status == IpsSaymentAdvice::STATUS_RECONCILED
      logger.error("payment #{payment.id} is not ready to be imported")
      payment.update!(status: IpsPayment::STATUS_IMPORT_FAILED, status_message: "payment is not ready for import")
      return
    end

    payment.update!(status: Ipspayment::STATUS_PROCESSING, status_message: nil)

    begin

      Royalties::Ips::ImportHandler.import(payment)

    rescue => e
      raise if Env["debug"]
      Rails.logger.error("Error handling import: #{e.message}")
      OhoError.create(
        owner: payment,
        label: "Importing #{payment.payment_date}",
        message: e.message,
        level: OhoError::ERROR
      )
      payment.update!(status: Ipspayment::STATUS_FAILED_IMPORT, status_message: e.message)
    end
    logger.info("finishing IPS job")
  end
end
