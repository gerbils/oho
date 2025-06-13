require_relative './parse_statement'
require 'pry'

module Royalties::Ips; end
module Royalties::Ips::StatementUpload
  extend self
  extend Royalties::Shared


  def handle(statement)
    sleep(5)
    file = statement.upload_wrapper.file
    excel_file_attached?(file)
    add_details_to_upload(statement.upload_wrapper, file)

    statement =  Royalties::Ips::ParseStatement.parse(
      statement,
      statement.upload_wrapper.file.download,
      'xlsx')
     save_statement(statement)

  rescue StandardError => e
    raise if ENV['debug']
    OhoError.create(object: statement, label: "Error uploading IPS statement", message: e.message, level: OhoError::ERROR)
    statement.status = IpsStatement::STATUS_FAILED_UPLOAD
    statement.save!
  end

  private

  def save_statement(statement)
    IpsStatement.transaction do
      save_details = statement.expenses + statement.revenues
      statement.expenses = []
      statement.revenues = []
      statement.status = IpsStatement::STATUS_INCOMPLETE   # still need details uploaded
      statement.save!

      statement.upload_wrapper.id_of_created_object = statement.id
      statement.upload_wrapper.save!

      save_details.each do |detail|
        detail.ips_statement = statement
        detail.save!
      end
    end
  end

  # def record_error(statement, message)
  #   statement.status_message = message
  #   statement.status = IpsStatement::STATUS_FAILED_UPLOAD
  #   statement.save!
  # end
  #

end
