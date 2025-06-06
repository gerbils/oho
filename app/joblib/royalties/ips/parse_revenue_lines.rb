require 'roo'
require "bigdecimal"

module Royalties; end
module Royalties::Ips; end

module Royalties::Ips::ParseRevenueLines
  extend self
  extend Royalties::Shared


  HEADER_NAMES = [
    "EAN",
    "Title",
    "Format",
    "List Amount",
    "Pub Alpha",
    "Brand Category",
    "Imprint",
    "Date",
    "Customer PO / Claim #",
    "Invoice / Credit Memo #",
    "Customer Discount",
    "Type",
    "Qty",
    "Value",
    "HQ Account #",
    "Headquarter",
    "Shipping Location",
    "SL City",
    "SL State",
  ]

  # sheet name to db column
  HEADER_MAP = Hash[
    HEADER_NAMES.map do |h|
      [ h, h.downcase.sub(%r{/}, 'or').sub(/#/, 'no').gsub(/\s+/, '_') ]
    end
  ]

  HEADER_COL_MAP = HEADER_NAMES.each_with_index.reduce({}) { |result, (name, index)| result[name] = index+1; result }

  def sanity_check(sheet)
    headers = sheet.row(sheet.first_row)
    if headers != HEADER_NAMES
      fail
      raise "Uploading revenue sheet. Headers do not match\n: expected #{BASE_HEADERS.inspect}\n but got #{headers.inspect}"
    end
  end

  def parse(content)
    sheet = open_spreadsheet(content, 'xlsm')
    sanity_check(sheet)
    rows = []

    n = sheet.first_row + 1
    while (n <= sheet.last_row)
      record = IpsRevenueLine.new
      HEADER_MAP.each do |sheet_col_name, db_column_name|
        value = sheet.excelx_value(n, HEADER_COL_MAP[sheet_col_name])
        if value
          value = value.strip
          value = nil if value.empty?
        end
        record[db_column_name] = value
      end
      rows << record
      n += 1
    end

    { status: :ok, rows: rows }
  # rescue => e
  #   Rails.logger.error "Error parsing IPS Revenue detail: #{e.message}"
  #   return { status: :error, message: e.message }
  end
end


