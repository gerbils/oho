class Lp::UploadRoyaltyJob < ApplicationJob
  queue_as :default

  def perform(upload_id)
console
    logger.info("starting LP import job")
    upload = UploadWrapper.find(upload_id)

    statement = LpStatement.new_with_upload(upload)
    begin
      Royalties::Lp::StatementUpload.handle(statement)
    rescue StandardError => e
      raise if ENV['debug']
      Rails.logger.error("Error handling lp upload: #{e.message}")
      statement.save!(status: LpStatement::STATUS_FAILED_UPLOAD, status_message: e.message)
    end
    logger.info("finishing LP import job")
  end
end
