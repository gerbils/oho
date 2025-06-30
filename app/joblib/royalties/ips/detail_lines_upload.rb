require "roo"

module Royalties::Ips; end
module Royalties::Ips::DetailLinesUpload
  extend self
  extend Royalties::Shared

  def handle(statement, upload_wrapper)
    file = upload_wrapper.file

    excel_file_attached?(file)
    add_details_to_upload(upload_wrapper, file)

    rows = Royalties::Ips::ParseDetailLines.parse(
      statement,
      file.download,
      'xlsx')

    map_isbns_to_skus(rows)
    save_rows(statement, upload_wrapper, rows)

  rescue StandardError => e
    raise if ENV['debug']
    OhoError.create(owner: statement, label: "Uploading #{file.filename}", message: e.message, level: OhoError::ERROR)
  end

  private

  def map_isbns_to_skus(rows)
    errors = []
    rows.each do |row|
      isbn = row.ean
      case  Product.product_and_sku_for_isbn(isbn)

      in [ nil, nil ]                  # non-specific expense
        row.sku_id = nil

      in [ Product => product, Sku => sku ]
        if row.title.blank? ||titles_similar(product.title, row[:title])
          row.sku_id = sku.id
        else
          errors << "Title mismatch #{isbn}: #{product.title.inspect} doesn't start with #{row[:title].inspect} (#{normalize(product.title)} vs. #{normalize(row[:title])} )"
        end
      else
        errors << "ISBN #{isbn} not found"
      end

      if errors.length > 0
        errors << "Too many errors"
        break
      end
    end

    if errors.empty?
      rows.first
    else
      raise errors.join("\n")
    end
  end

  def normalize(title)
    title
      .downcase
      .tr("^a-z0-9", "")
      .sub(/(2nd|3rd|4th|5th|6th|7th|8th|9th|second|third|fourth|fifth|sixth|seventh|eighth|ninth)ed(ition)?/, "")
      .strip
  end

  def titles_similar(pip, ips)
    pip = normalize(pip)
    ips = normalize(ips)
    len = [ pip.length, ips.length ].min
    fail "zero length title" if len == 0
    pip[0...len] == ips[0...len]
  end

  # try to match the sum of the rows to a revenue detail line. If found, attach the rows there,
  # otherwise throw them away and record an error
  #
  def save_rows(statement, upload, rows)
    total   = rows.reduce(BigDecimal("0.00000")) { |sum, row| sum + row.amount }
    total   = total.round(2)
    details = statement.get_matching_details_for_total(total)

    case details.length
    when 0
      raise "No matching revenue detail for total #{total.to_f}"

    when 1
      detail = details.first

      unless detail.ips_detail_lines.empty?
        raise("Duplicate upload of details speadsheet for `#{detail.detail}' (total #{"%9.2f" % [total]})\n" +
              "files #{upload.file.filename} and #{detail.upload_wrapper.file.filename}")
      end

      detail.upload_wrapper = upload

      rows.each do |row|
        detail.ips_detail_lines << row
      end

      detail.update!(uploaded_at: Time.now)
      return detail

    else
      raise "Too many matching revenue details for total #{total.to_f}: #{details.length}\n" +
        details.map { |d| "#{d.detail}: #{d.due_this_month}" }.join("\n")
    end

  rescue ActiveRecord::RecordNotUnique
    raise "This file has already been uploaded"
  end

end

