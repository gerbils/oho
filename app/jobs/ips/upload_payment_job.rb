
class Ips::UploadPaymentJob < ApplicationJob
  queue_as :default

  def perform(payment_id, upload_id)
    logger.info("starting IPS payment advice upload job")
    upload = UploadWrapper.find(upload_id)
    if upload.status != UploadWrapper::STATUS_PENDING
      logger.error("Upload is not pending")
      return
    end

    payment = IpsPaymentAdvice.find(payment_id)

    upload.update!(status: UploadWrapper::STATUS_PROCESSING, status_message: nil)

    begin
      Royalties::Ips::PaymentAdviceUpload.handle(payment, upload)
      payment.save!
    rescue StandardError => e
      raise if ENV['debug']
      Rails.logger.error("Error handling ips upload: #{e.message}")
      OhoError.create(owner: payment, label: "Error uploading IPS payment advice", message: e.message, level: OhoError::ERROR)
    end
    logger.info("finishing IPS payment advice upload job")
  end
end
