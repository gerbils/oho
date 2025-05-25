require_relative '../../../lib/royalties/dispatcher'

class Lp::ImportRoyaltyJob < ApplicationJob
  queue_as :default

  def perform(upload_id)
    logger.info("starting import `job")
    upload = Upload.find(upload_id)
    if upload.status != Upload::STATUS_UPLOADED
      logger.error("Upload is not pending")
      upload.update!(status: Upload::STATUS_IMPORT_FAILED, error_msg: "Upload is not pending")
      return
    end
    upload.update!(status: Upload::STATUS_PROCESSING, error_msg: nil)
    Royalties::Dispatcher.handle_import(upload)
    logger.info("finishing import job")
  end
end
