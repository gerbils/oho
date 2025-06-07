require 'roo'
require "bigdecimal"

module Royalties::Lp::ParseStatement
  extend self
  extend Royalties::Shared

  HEADER_ROW = 16
  HEADERS = {
    "ISBN" => 2,
    "eISBN" => 3,
    "Title" => 4,
    "Publisher" => 5,
    "Author" => 6,
    "Channel" => 7,
    "Sales" => 9,
    "Commission Rate" => 10,
    "Commission Earned" => 11,
  }
  PAYMENT_LABEL = 9
  PAYMENT_DUE   = PAYMENT_LABEL + 1


  def expect(sheet, row, col, expected_value, msg=expected_value)
    actual_value = sheet.cell(row, col)
    if expected_value =~ actual_value
      $1
    else
      raise "Expected #{msg} but got #{actual_value.inspect} in row: #{row}:\n#{sheet.row(row).inspect}\nPerhaps this isn't a Learning Platform file?"
    end
  end

  def sanity_check(sheet)
    expect(sheet, 3, 6, /^O'Reilly Quarterly Commission Statement$/, "Statement Header")
    expect(sheet, 4, 2, /^O'Reilly Media, Inc.$/)
    date = expect(sheet, 4, 6, %r{^Statement Date:\s+(\d{2}/\d{2}/\d{4})$}, "mm/dd/yyyy")
    date = Date.strptime(date, "%m/%d/%Y")
    period = expect(sheet, 5, 6, %r{^Statement Period:\s+(\w+ - \w+ \d{4})}, "Statement Period")
    HEADERS.each do |header, col|
      expect(sheet, HEADER_ROW, col, %r{^#{header}$})
    end
    [ date, period ]
  end

  def parse(statement, spreadsheet_data, extension)
    sheet = open_spreadsheet(spreadsheet_data, extension)
    date, period  = sanity_check(sheet)
    total = BigDecimal("0")

    statement.date_on_report = date
    statement.report_period  = period

    row = HEADER_ROW + 1
    while (row <= sheet.last_row)
      isbn = sheet.excelx_value(row, HEADERS["ISBN"])
      break if isbn.nil? || isbn.empty?
      line = LpStatementLine.new(
        isbn:              isbn,
        e_isbn:            sheet.cell(row, HEADERS["eISBN"]),
        title:             sheet.cell(row, HEADERS["Title"]),
        publisher:         sheet.cell(row, HEADERS["Publisher"]),
        author:            sheet.cell(row, HEADERS["Author"]),
        sales:             sheet.cell(row, HEADERS["Sales"]),
        commission_rate:   sheet.excelx_value(row, HEADERS["Commission Rate"]),
        commission_earned: sheet.excelx_value(row, HEADERS["Commission Earned"]),
      )

      statement.lp_statement_lines << line

      total += BigDecimal(line.commission_earned.to_s)
      row += 1
    end

    # look for total in sheet
    while row <= sheet.last_row
      break unless sheet.cell(row, PAYMENT_LABEL).nil?
      row += 1
    end
    expect(sheet, row, PAYMENT_LABEL, /^Payment Due$/)
    their_total = BigDecimal(sheet.excelx_value(row, PAYMENT_DUE))

    unless (their_total - total).abs < 0.0001
      raise "Total of rows (#{total.to_f}) does not agree with batch total (#{their_total.to_f})"
    end

    statement.statement_total = total

    return { status: :ok, statement: }

  rescue => e
    raise if ENV['debug']
    Rails.logger.error "Error parsing LP statement: #{e.message}"
    return { status: :error, message: e.message }
  end
end

