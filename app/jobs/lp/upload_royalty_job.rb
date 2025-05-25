require_relative '../../../lib/royalties/dispatcher'

class Lp::UploadRoyaltyJob < ApplicationJob
  queue_as :default

  def perform(upload_id)
    logger.info("starting job")
    upload = Upload.find(upload_id)
    if upload.status != Upload::STATUS_PENDING
      logger.error("Upload is not pending")
      return
    end
    upload.update!(status: Upload::STATUS_PROCESSING, error_msg: nil)
    Royalties::Dispatcher.handle_upload(upload)
    logger.info("finishing job")
  end
end
