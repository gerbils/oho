require_relative './parse_statement'

module Royalties::Lp; end
module Royalties::Lp::StatementUpload
  extend self
  extend Royalties::Shared


  def handle(statement, upload_wrapper)
    statement.clear_oho_errors
    file = upload_wrapper.file
    add_details_to_upload(upload_wrapper, file)
    excel_file_attached?(file)
    Royalties::Lp::ParseStatement.parse(
      statement,
      file.download,
      'xlsm')
    map_isbns_to_skus(statement)
    save_statement(statement)
  rescue StandardError => e
    raise if ENV['debug']
    error(statement, e.message)
    statement.status = LpStatement::STATUS_FAILED_UPLOAD
    statement.save!
  end

  private

  def error(statement, message)
    OhoError.create(owner: statement, label: "Error uploading LP statement", message: message, level: OhoError::ERROR)
  end

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

    error_count = 0
    lines.each do |line|
      isbn = line.isbn
      if match = isbn_map[isbn]
        match => { sku_id:, title: }
        if titles_similar(title, line.title)
          line.sku_id = sku_id
        else
          error(statement, "Title mismatch #{isbn}: #{title.inspect} doesn't start with #{line.title.inspect}")
          error_count += 1
        end
      else
        error(statement, "ISBN #{isbn} for #{line.title.inspect} not found in pip")
        error_count += 1
      end
      if error_count.length > 9
        fail "Too many errors; stopping"
      end
    end
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
    msg = case e
          when ActiveRecord::RecordNotUnique
            statement.date_on_report = "dup #{upload.id}: #{upload.date_on_report}"
            "This file has already been statemented"
          else
            e.message
          end
    fail msg
  end

end
