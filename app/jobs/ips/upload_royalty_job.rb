class Ips::UploadRoyaltyJob < ApplicationJob
  queue_as :default

  def perform(statement_id, upload_id)
    logger.info("starting IPS upload job")
    statement = IpsStatement.find(statement_id)
    upload_wrapper = UploadWrapper.find(upload_id)
    # begin
      Royalties::Ips::StatementUpload.handle(statement, upload_wrapper)
    # rescue StandardError => e
    #   raise if ENV['debug']
    #   Rails.logger.error("Error handling ips upload: #{e.message}")
    #   OhoError.create(owner: statement, label: "Error uploading IPS statement", message: e.message, level: OhoError::ERROR)
    # end
    logger.info("finishing IPS upload job")
  end
end
