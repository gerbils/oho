class Ips::UploadRevenueLinesJob < ApplicationJob
  queue_as :default

  def perform(upload_id)
    logger.info("starting IPS revenue lines upload job")
    upload = UploadWrapper.find(upload_id)
    if upload.status != UploadWrapper::STATUS_PENDING
      logger.error("Upload is not pending")
      return
    end
    upload.update!(status: UploadWrapper::STATUS_PROCESSING, status_message: nil)
    # begin
      Royalties::Ips::UploadRevenueLines.handle(upload)
    # rescue => e
    #   Rails.logger.error("Error handling upload: #{e.message}")
    #   upload.update!(status: Upload::STATUS_FAILED_UPLOAD, status_message: e.message)
    # end
    logger.info("finishing details IPS upload revenue lines job")
  end
end
