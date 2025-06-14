require_relative './parse_statement'
require 'pry'

module Royalties::Ips; end
module Royalties::Ips::StatementUpload
  extend self
  extend Royalties::Shared


  def handle(statement, upload_wrapper)
    statement.clear_oho_errors
    file = upload_wrapper.file
    excel_file_attached?(file)
    add_details_to_upload(upload_wrapper, file)

    statement =  Royalties::Ips::ParseStatement.parse(
      statement,
      upload_wrapper.file.download,
      'xlsx')
     save_statement(statement)

  rescue StandardError => e
    raise if ENV['debug']
    OhoError.create(owner: statement, label: "Error uploading IPS statement", message: e.message, level: OhoError::ERROR)
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

      save_details.each do |detail|
        detail.ips_statement = statement
        detail.save!
      end
    end
  end
end
