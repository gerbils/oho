class Lp::ImportRoyaltyJob < ApplicationJob
  queue_as :default

  def perform(statement_id)
    logger.info("starting import job")
    statement = LpStatement.find(statement_id)
    if statement.status != LpStatement::STATUS_UPLOADED
      logger.error("Import is not pending")
      statement.update!(status: LpStatement::STATUS_IMPORT_FAILED, status_message: "Import is not pending")
      return
    end
    statement.update!(status: LpStatement::STATUS_PROCESSING, status_message: nil)
    begin
      Royalties::Lp::ImportHandler.handle(statement)
    rescue => e
      raise if ENV["debug"]
      Rails.logger.error("Error handling import: #{e.message}")
      statement.update!(status: LpStatement::STATUS_FAILED_IMPORT, status_message: e.message)
    end
    logger.info("finishing job")
  end
end
