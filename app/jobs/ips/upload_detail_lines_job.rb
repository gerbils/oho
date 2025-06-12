class Ips::UploadDetailLinesJob < ApplicationJob
  queue_as :default

  def perform(statement_id, upload_id)
    logger.info("starting IPS  upllsoad job")
    upload = UploadWrapper.find(upload_id)
    if upload.status != UploadWrapper::STATUS_PENDING
      logger.error("Upload is not pending")
      return
    end

    statement = IpsStatement.find(statement_id)

    upload.update!(status: UploadWrapper::STATUS_PROCESSING, status_message: nil)

    begin
      detail = Royalties::Ips::DetailLinesUpload.handle(statement, upload)
      detail.save!
        statement.mark_if_complete
        statement.save!

    rescue => e
      raise if ENV['debug']
      Rails.logger.error("Error handling upload: #{e.message}")
      statement.update!(status: IpsStatement::STATUS_FAILED_UPLOAD, status_message: e.message)
    end
    logger.info("finishing details IPS upload job")
  end
end
