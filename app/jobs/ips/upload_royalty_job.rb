class Ips::UploadRoyaltyJob < ApplicationJob
  queue_as :default

  def perform(statement_id)
    logger.info("starting IPS upload job")
    statement = IpsStatement.find(statement_id)
    begin
      Royalties::Ips::StatementUpload.handle(statement)
    rescue StandardError => e
      raise if ENV['debug']
      Rails.logger.error("Error handling ips upload: #{e.message}")
      OhoError.create(object: statement, label: "Error uploading IPS statement", message: e.message, level: OhoError::ERROR)
    end
    logger.info("finishing IPS upload job")
  end
end
