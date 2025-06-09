require_relative './parse_statement'
require 'pry'

module Royalties::Ips; end
module Royalties::Ips::StatementUpload
  extend self
  extend Royalties::Shared


  def handle(statement)
    step = 0
    result = nil # for scoping

    loop do   # Poor man's "do"
      result = case step
               when 0
                 error = excel_file_attached?(statement.upload_wrapper.file)
                 if error
                   { status: :error, message: error }
                 else
                   { status: :ok, statement: }
                 end
               when 1
                 Royalties::Ips::ParseStatement.parse(
                   statement,
                   statement.upload_wrapper.file.download,
                   'xlsx')
               when 2
                 save_statement(statement)
               when 3
                 break
               when :error
                 record_error(statement, result[:message])
                 break
               end
      if result[:status] == :ok
        step += 1
        statement = result[:statement]
      else
        step = :error
      end
    end
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

    { status: :ok}

  rescue => e
    raise if ENV['debug']
    { status: :error, message: e.message }
  end

  def record_error(statement, message)
    statement.status_message = message
    statement.status = IpsStatement::STATUS_FAILED_UPLOAD
    statement.save!
  end


end
