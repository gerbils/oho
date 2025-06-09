require "roo"

# HEADERS = [
#   "EAN",
#   "Title",
#   "Format",
#   "List Amount",
#   "Pub Alpha",
#   "Brand Category",
#   "Imprint",
#   "Date",
#   "Customer PO / Claim #",
#   "Invoice / Credit Memo #",
#   "Customer Discount",
#   "Type",
#   "Qty",
#   "Value",
#   "HQ Account #",
#   "Headquarter",
#   "Shipping Location",
#   "SL City",
#   "SL State"
# ]

module Royalties::Ips; end
module Royalties::Ips::UploadRevenueLines
  extend self
  extend Royalties::Shared

  def handle(statement, upload_wrapper)
    file = upload_wrapper.file
    step = 0
    result = nil # for scoping

    loop do   # Poor man's "do"
      result = case step
               when 0
                 error = excel_file_attached?(file)
                 if error
                   { status: :error, message: error }
                 else
                   { status: :ok, upload_wrapper: }
                 end

               when 1
                 add_details_to_upload(upload_wrapper, file)

               when 2
                 Royalties::Ips::ParseRevenueLines.parse(file.download)

               when 3
                 map_isbns_to_skus(result[:rows])

               when 4
                 save_rows(statement, upload_wrapper, result[:rows])

               when 5
                 break

               when -1
                 record_error(upload_wrapper, result[:message])
                 break

               end
      if result[:status] == :ok
        step += 1
      else
        step = -1
      end
    end
  end

  private

  def add_details_to_upload(upload, file)
    upload.status_message = nil
    upload.filename = file.filename.to_s
    upload.size = file.byte_size
    upload.save!
    { status: :ok }
  rescue => e
    raise if ENV['debug']
    { status: :error, message: e.message }
  end

  def map_isbns_to_skus(rows)
    errors = []
    rows.each do |row|
      isbn = row.ean
      case  Product.product_and_sku_for_isbn(isbn)
      in [ Product => product, Sku => sku ]
        if titles_similar(product.title, row[:title])
          row[:sku_id] = sku.id
        else
          errors << "Title mismatch #{isbn}: #{title.inspect} doesn't start with #{row[:title].inspect}"
        end
      end

      if errors.length > 10
        errors << "Too many errors"
        break
      end
    end

    if errors.empty?
      { status: :ok, rows: rows }
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

  # try to match the sum of the rows to a revenue detqil line. If found, attach the rows there,
  # otherwise throw them away and record an error
  #
  def save_rows(statement, upload, rows)
    total = rows.reduce(BigDecimal("0.00")) { |sum, row| sum + row.value }
    details = statement.get_matching_details_for_total(total)

    case details.length
    when 0
      { status: :error, message: "No matching revenue detail for total #{total.to_f}" }
    when 1
      detail = details.first
      rows.each { |row| row.upload_wrapper = upload }
      detail.ips_revenue_lines << rows
      detail.save!
      { status: :ok, message: "Attached #{rows.length} revenue lines to `#{detail.detail} for total #{total.to_f}" }
    else
      { status: :error, message: "Too many matching revenue details for total #{total.to_f}: #{details.length}" }
    end
  rescue StandardError => e
    raise if ENV['debug']
    msg = case e
          when ActiveRecord::RecordNotUnique
            upload.date_on_report = "dup #{upload.id}: #{upload.date_on_report}"
            "This file has already been uploaded"
          else
            e.message
          end

    { status: :error, message: msg }
  end

  def record_error(upload_wrapper, message)
    upload_wrapper.status_message = message
    upload_wrapper.status = IpsStatement::STATUS_FAILED_UPLOAD
    upload_wrapper.save!
  end

end

