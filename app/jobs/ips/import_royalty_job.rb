class Ips::ImportRoyaltyJob < ApplicationJob
  queue_as :default

  def perform(statement_id)
    logger.info("starting IPS import job")
    statement = IpsStatement.find(statement_id)
    OhoError.clear_errors(statement)

    unless statement.ready_to_import?
      logger.error("statement #{statement.id} is not ready to be imported")
      statement.update!(status: IpsStatement::STATUS_IMPORT_FAILED, status_message: "statement is not ready for import")
      return
    end

    statement.update!(status: IpsStatement::STATUS_PROCESSING, status_message: nil)

    begin

      Royalties::Ips::ImportHandler.import(statement)

    # rescue => e
    #   Rails.logger.error("Error handling import: #{e.message}")
    #   OhoError.create(
    #     owner: statement,
    #     label: "Importing #{statement.month_ending}",
    #     message: e.message,
    #     level: OhoError::ERROR
    #   )
    #   statement.update!(status: IpsStatement::STATUS_FAILED_IMPORT, status_message: e.message)
    end
    logger.info("finishing IPS job")
  end
end
