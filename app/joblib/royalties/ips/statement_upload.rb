require_relative './parse_statement'
require 'pry'

module Royalties::Ips; end
module Royalties::Ips::StatementUpload
  extend self
  extend Royalties::Shared


  def handle(upload)
    file = upload.file
    step = 0
    result = nil # for scoping

    loop do   # Poor man's "do"
      result = case step
               when 0
                 excel_file_attached?(file)
               when 1
                 Royalties::Ips::ParseStatement.parse_statement(file.download)
               when 2
                 save_statement(upload, result[:statement])
               when 3
                 break
               when :error
                 record_error(upload, result[:message])
                 break
               end
      if result[:status] == :ok
        step += 1
      else
        step = :error
      end
    end
  end

  private

  def save_statement(upload, statement)
    UploadWrapper.transaction do
      statement.upload_wrapper = upload
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

    # has to be outside the transaction in order to pick up the statement.id
    upload.status = Upload::STATUS_INCOMPLETE   # still need details uploaded
    upload.id_of_created_object = statement.id
    upload.save!

    { status: :ok}

  # rescue => e  TODO: undo me
  #   { status: :error, message: e.message }
  end

  def record_error(statement, message)
    statement.status_message = message
    statement.status = IpsStatement::STATUS_FAILED_UPLOAD
    statement.save!
  end


end
