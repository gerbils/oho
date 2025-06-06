class Ips::ImportRoyaltyJob < ApplicationJob
  queue_as :default

  def perform(upload_id)
    logger.info("starting IPS import job")
    upload = Upload.find(upload_id)
    if upload.status != Upload::STATUS_UPLOADED
      logger.error("Upload is not pending")
      upload.update!(status: Upload::STATUS_IMPORT_FAILED, error_msg: "Upload is not pending")
      return
    end
    upload.update!(status: Upload::STATUS_PROCESSING, error_msg: nil)
    begin
      Royalties::Ips::ImportHandler.handle_import(upload)
    rescue => e
      Rails.logger.error("Error handling import: #{e.message}")
      upload.update!(status: Upload::STATUS_FAILED_IMPORT, error_msg: e.message)
    end
    logger.info("finishing IPS job")
  end
end
