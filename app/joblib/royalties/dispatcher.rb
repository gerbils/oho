module Royalties; end
module Royalties::Lp; end

require_relative "./lp/import_handler"
require_relative "./lp/upload_handler"

module Royalties::Dispatcher
  extend self

  def handle_import(upload)
    find_handler(upload.upload_channel)::ImportHandler.handle_import(upload)
  rescue => e
    Rails.logger.error("Error handling import: #{e.message}")
    upload.update!(status: Upload::STATUS_FAILED_IMPORT, error_msg: e.message)
  end

  def handle_upload(upload)
    find_handler(upload.upload_channel)::UploadHandler.handle_upload(upload)
  rescue => e
    Rails.logger.error("Error handling upload: #{e.message}")
    upload.update!(status: Upload::STATUS_FAILED_UPLOAD, error_msg: e.message)
  end

  private

  SOURCE_TO_HANDLER = {
    Upload::CHANNEL_LP => Royalties::Lp,
  }

  def find_handler(upload_channel)
   SOURCE_TO_HANDLER[upload_channel] || fail("No handler found for upload channel #{upload_channel}")
  end

end

