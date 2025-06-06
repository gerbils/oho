class Ips::UploadRoyaltyJob < ApplicationJob
  queue_as :default

  def perform(upload_id)
    logger.info("starting IPS upload job")
    upload = UploadWrapper.find(upload_id)
    if upload.status != Upload::STATUS_PENDING
      logger.error("Upload is not pending")
      return
    end
    upload.update!(status: Upload::STATUS_PROCESSING, status_message: nil)
    begin
      Royalties::Ips::StatementUpload.handle(upload)
    # rescue => e
    #   Rails.logger.error("Error handling upload: #{e.message}")
    #   upload.update!(status: Upload::STATUS_FAILED_UPLOAD, error_msg: e.message)
    end
    logger.info("finishing IPS upload job")
  end
end
