require_relative './parse_statement'

module Royalties::Lp; end
module Royalties::Lp::StatementUpload
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
                 ee
               when 1
                 Royalties::Lp::ParseStatement.parse(
                   statement,
                   statement.upload_wrapper.file.download,
                   'xlsm')
               when 2
                 map_isbns_to_skus(statement)
               when 3
                 save_statement(statement)
               when 4
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

  def map_isbns_to_skus(statement)
    lines = statement.lp_statement_lines
    ebooks = Sku
      .where(media: "electronic_book")
      .joins(:product)
      .pluck(:id, :title, :isbn13, :safari_isbn, :channel_epub_isbn, :kindle_edition_isbn, :channel_pdf_isbn )  # yup, it is the SKU id...

    isbn_map = ebooks.reduce({}) do |result, query_row|
      sku_id = query_row.shift
      title = query_row.shift
      paper_isbn = query_row.shift
      info = { sku_id:, title:, paper_isbn: }
      query_row.each do |eisbn|
        if eisbn && !eisbn.empty?
          if result[eisbn] && result[eisbn][:sku_id] != sku_id
            fail "ISBN #{eisbn.inspect} is use by both SKU #{result[eisbn][:sku_id]} and SKU #{sku_id}"
          end
          result[eisbn] = info
        end
      end
      result
    end

    errors = []
    lines.each do |line|
      isbn = line.isbn
      if match = isbn_map[isbn]
        match => { sku_id:, title: }
        if titles_similar(title, line.title)
          line.sku_id = sku_id
        else
          errors << "Title mismatch #{isbn}: #{title.inspect} doesn't start with #{line.title.inspect}"
        end
      else
        errors << "ISBN #{isbn} for #{line.title.inspect} not found in pip"
      end
      if errors.length > 9
        errors << "Too many errors; stopping"
        return { status: :error, message: errors.join("\n") }
      end
    end

    if errors.empty?
      { status: :ok, statement: statement }
    else
      { status: :error, message: errors.join("\n") }
    end
  rescue => e
    raise if ENV['debug']
    { status: :error, message: e.message }
  end

  def titles_similar(pip, lp)
    pip = pip.downcase.tr("^a-z0-9", " ")
    lp  = lp.downcase.tr("^a-z0-9", " ").sub(/2nd/, "second").sub(/3rd/, "third")
    pip[0..10] == lp[0..10]
  end

  def save_statement(statement)
    statement.status = LpStatement::STATUS_UPLOADED
    statement.save!
    { status: :ok}
  rescue => e
    raise if ENV['debug']
    msg = case e
          when ActiveRecord::RecordNotUnique
            statement.date_on_report = "dup #{upload.id}: #{upload.date_on_report}"
            "This file has already been statemented"
          else
            e.message
          end

    { status: :error, message: msg }
  end

  def record_error(statement, message)
    statement.status_message = message
    statement.status = LpStatement::STATUS_FAILED_UPLOAD
    statement.save!
  end


end
