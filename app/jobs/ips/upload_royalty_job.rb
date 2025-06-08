class Ips::UploadRoyaltyJob < ApplicationJob
  queue_as :default

  def perform(upload_id)
    logger.info("starting IPS upload job")
    upload = UploadWrapper.find(upload_id)
    statement = IpsStatement.new_with_upload(upload)
    begin
      Royalties::Ips::StatementUpload.handle(statement)
    rescue StandardError => e
      raise if ENV['debug']
      Rails.logger.error("Error handling lp upload: #{e.message}")
      statement.save!(status: IpsStatement::STATUS_FAILED_UPLOAD, status_message: e.message)
    end
    logger.info("finishing IPS upload job")
  end
end
