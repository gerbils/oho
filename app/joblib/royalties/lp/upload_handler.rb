require_relative './parse_xls'

module Royalties::Lp; end
module Royalties::Lp::UploadHandler
  extend self

  def handle_upload(upload)
    file = upload.uploaded_file
    step = 0
    result = nil # for scoping
    date = period = rows = total = nil

    loop do   # Poor man's "do"
      result = case step
               when 0
                 sanity_check_ok?(file)
               when 1
                 add_details_to_upload(upload, file)
               when 2
                 Royalties::Lp::ParseXls.parse_statement(file.download)
               when 3
                 date = result[:date]
                 period = result[:period]
                 total = result[:total]
                 map_isbns_to_skus(result[:rows])
               when 4
                 save_rows(upload, date, period, result[:rows], total)
               when 5
                 break
               end
      if result[:status] == :ok
        step += 1
      else
        record_error(upload, result[:message])
        break
      end
    end
  end

  private

  def sanity_check_ok?(file)
    error = case
            when !file.attached?
              "File is not attached"
            when file.content_type !~ /vnd.ms-excel.sheet|officedocument.spreadsheetml/
              "Mime type #{file.content_type} is not an Excel sheet"
            else
              nil
            end
    if error
      { status: :error, message: error }
    else
      { status: :ok }
    end
  end

  def add_details_to_upload(upload, file)
    upload.error_msg = nil
    upload.filename = file.filename.to_s
    upload.filesize = file.byte_size
    upload.save!
    { status: :ok }
  rescue => e
    { status: :error, message: e.message }
  end

  def map_isbns_to_skus(rows)
    ebooks = Sku
      .where(media: "electronic_book")
      .joins(:product)
      .pluck(:id, :title, :isbn13, :kindle_edition_isbn, :safari_isbn, :channel_epub_isbn, :channel_pdf_isbn )  # yup, it is the SKU id...

    isbn_map = ebooks.reduce({}) do |result, query_row|
      sku_id = query_row.shift
      title = query_row.shift
      paper_isbn = query_row.shift
      info = { sku_id:, title:, paper_isbn: }
      query_row.each do |eisbn|
        if eisbn && !eisbn.empty?
          if result[eisbn]
            fail "Duplicate ISBN #{eisbn} for SKU #{result[eisbn][:sku_id]} and SKU #{sku_id}"
          end
          result[eisbn] = info
        end
      end
      result
    end

    errors = []
    rows.each do |row|
      isbn = row[:isbn]
      if match = isbn_map[isbn]
        match => { sku_id:, title: }
        if titles_similar(title, row[:title])
          row[:sku_id] = sku_id
        else
          errors << "Title mismatch #{isbn}: #{title.inspect} doesn't start with #{row[:title].inspect}"
        end
      else
        errors << "ISBN #{isbn} for #{row[:title].inspect} not found in pip"
      end
      if errors.length > 9
        errors << "Too many errors; stopping"
        return { status: :error, message: errors.join("\n") }
      end
    end

    if errors.empty?
      { status: :ok, rows: rows }
    else
      { status: :error, message: errors.join("\n") }
    end
  rescue => e
    { status: :error, message: e.message }
  end

  def titles_similar(pip, lp)
    pip = pip.downcase.tr("^a-z0-9", " ")
    lp  = lp.downcase.tr("^a-z0-9", " ").sub(/2nd/, "second").sub(/3rd/, "third")
    pip[0..10] == lp[0..10]
  end

  def save_rows(upload, date, period, rows, total)
    Upload.transaction do
      upload.status = Upload::STATUS_UPLOADED
      upload.date_on_report = date
      upload.report_period = period
      upload.statement_total = total
      upload.save!
      rows.each {|row| row[:upload_id] = upload.id }
      RoyaltyRawLpDatum.insert_all(rows)
      { status: :ok}
    end
  rescue => e
    msg = case e
          when ActiveRecord::RecordNotUnique
            upload.date_on_report = "dup #{upload.id}: #{upload.date_on_report}"
            "This file has already been uploaded"
          else
            e.message
          end

    { status: :error, message: msg }
  end

  def record_error(upload, message)
    upload.error_msg = message
    upload.status = Upload::STATUS_FAILED_UPLOAD
    upload.save!
  end
end
