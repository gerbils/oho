class Lp::UploadRoyaltyJob < ApplicationJob
  queue_as :default

  def perform(upload_id)
    logger.info("starting LP import job")
    upload = UploadWrapper.find(upload_id)
    if upload.status != UploadWrapper::STATUS_PENDING
      logger.error("Upload is not pending")
      return
    end
    upload.update!(status: UploadWrapper::STATUS_PROCESSING, status_message: nil)
    begin
      Royalties::Lp::StatementUpload.handle(upload)
    # rescue => e   TODO: activate
    #   Rails.logger.error("Error handling lp upload: #{e.message}")
    #   upload.update!(status: Upload::STATUS_FAILED_UPLOAD, status_message: e.message)
    end
    logger.info("finishing LP import job")
  end
end
