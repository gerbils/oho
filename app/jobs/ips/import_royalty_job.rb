class Ips::ImportRoyaltyJob < ApplicationJob
  queue_as :default

  def perform(statement_id)
    logger.info("starting IPS import job")
    statement = IpsStatement.find(statement_id)
    unless statement.ready_for_import?
      logger.error("statement #{statement.id} is not ready to be imported")
      statement.update!(status: statement::STATUS_IMPORT_FAILED, error_msg: "statement is not ready for import")
      return
    end
    statement.update!(status: statement::STATUS_PROCESSING, error_msg: nil)
    begin
      Royalties::Ips::ImportHandler.handle_import(statement)
    rescue => e
      Rails.logger.error("Error handling import: #{e.message}")
      OhoError.create(
        owner: statement,
        label: "Importing #{statement.month_ending}",
        message: e.message,
        level: OhoError::ERROR
      )
      statement.update!(status: statement::STATUS_FAILED_IMPORT, error_msg: e.message)
    end
    logger.info("finishing IPS job")
  end
end
