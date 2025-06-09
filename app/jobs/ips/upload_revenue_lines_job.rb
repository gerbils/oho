class Ips::UploadRevenueLinesJob < ApplicationJob
  queue_as :default

  def perform(statement_id, upload_id)
    logger.info("starting IPS revenue lines upload job")
    upload = UploadWrapper.find(upload_id)
    if upload.status != UploadWrapper::STATUS_PENDING
      logger.error("Upload is not pending")
      return
    end
    statement = IpsStatement.find(statement_id)
    upload.update!(status: UploadWrapper::STATUS_PROCESSING, status_message: nil)
    begin
      Royalties::Ips::UploadRevenueLines.handle(statement, upload)
    rescue => e
      raise if ENV['debug']
      Rails.logger.error("Error handling upload: #{e.message}")
      upload.update!(status: Upload::STATUS_FAILED_UPLOAD, status_message: e.message)
    end
    logger.info("finishing details IPS upload revenue lines job")
  end
end
