class Lp::UploadRoyaltyJob < ApplicationJob
  queue_as :default

  def perform(statement_id, upload_id)
    logger.info("starting LP import job")
    statement = LpStatement.find(statement_id)
    upload_wrapper = UploadWrapper.find(upload_id)

    begin
      Royalties::Lp::StatementUpload.handle(statement, upload_wrapper)
    rescue StandardError => e
      raise if ENV['debug']
      Rails.logger.error("Error handling lp upload: #{e.message}")
      OhoError.create(owner: statement, label: "Error uploading LP statement", message: e.message, level: OhoError::ERROR)
    end
    logger.info("finishing LP import job")
  end
end
