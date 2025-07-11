require 'roo'
require 'bigdecimal'


module Royalties::Ips::ParsePaymentAdvice
  extend self
  extend Royalties::Shared

  def parse(advice, content, file_type)
    sheet = open_spreadsheet(content, file_type)
    check_header(sheet.row(24))
    advice = validate_expected_format(sheet, advice)
    advice = load_rows(advice, sheet, 25)
    reconcile(advice)
    advice
  end

  private

  def row_error(row, col_number, row_number, value, expected)
    msg = [
    "In cell #{col_number}#{row_number}:",
      "Expected   #{expected.inspect}, got #{value.inspect}",
      "Whole row: #{row.inspect}"
    ]
    raise msg.join("\n")
  end

  def check_cell(sheet, col, row, value)
    cell_value = sheet.cell(col, row).strip
    row_error(sheet.row(row), col, row, cell_value, value) unless cell_value == value
  end

  def check_and_get_cell(sheet, col, row, expected, value_col, value_row)
    check_cell(sheet, col, row, expected)
    value = sheet.excelx_value(value_col, value_row)
    raise("Expected value in #{value_col}#{value_row}") if value.nil? || value.to_s.strip.empty?
    value
  end

  def validate_expected_format(sheet, advice)
    raise 'Unexpected first row/column' unless sheet.first_row == 1 && sheet.first_column == 1
    check_cell(sheet, "E", 1, "Payment Advice")
    check_cell(sheet, "B", 9, "PRAGMATIC PROGRAMMERS LLC")
    advice.payment_reference    = check_and_get_cell(sheet, "A", 16, "Payment Reference:", "B", 16)
    advice.pay_cycle            = check_and_get_cell(sheet, "M", 10, "Pay Cycle:", "Q", 10)
    advice.pay_cycle_seq_number = check_and_get_cell(sheet, "M", 11, "Pay Cycle Seq Number:", "Q", 11)
    advice.payment_date         = mmddyyyy(check_and_get_cell(sheet, "A", 17, "Payment Date:", 'B', 17), 17, 'A')
    last = sheet.last_row
    check_cell(sheet, "A", last, "Private and Confidential")

    last -= 1
    while last > 20 && sheet.cell("F", last).nil?
      last -= 1
    end
    raise("Couldn't find total line") unless last > 20

    advice.total_amount = BigDecimal(sheet.excelx_value("R", last))
    advice
  end

  EXPECTED_HEADER = [
    "Invoice Number", nil, " Invoice Date", nil, nil, "Voucher ID",
    "     Gross Amount", nil, nil, nil, nil, "Discount Taken", nil, nil, nil, nil, nil,
    "        Paid Amt", nil, nil, nil, nil
  ]
  def check_header(row)
    unless row == EXPECTED_HEADER
      raise("Row 24: looking for header\nexpected: #{EXPECTED_HEADER.inspect}\ngot #{row.inspect}")
    end
  end

  def mmddyyyy(value, r, c)
    if value !~ %r{([01]\d)/([0123]\d)/(2\d\d\d)} # MM/DD/YYYY
      rqaise "Invalid date: #{value.inspect} at #{c}#{r}"
    end
    Date.new($3.to_i, $1.to_i, $2.to_i) rescue raise("Invalid date: #{value.inspect} (#$3 #$1 #$2)")
  end


  def load_rows(advice, sheet, row)
    loop do
      invoice_number = sheet.excelx_value('A', row)
      break if invoice_number.nil? || invoice_number.strip.empty?
      line = advice.ips_payment_advice_lines.new
      line.invoice_number = invoice_number.sub(%r{<html><b>.*?</b>}, '').sub(%r{\s*</html>}, '')
      line.invoice_date   = mmddyyyy(sheet.excelx_value('C', row), row, 'C')
      line.voucher_id     = sheet.excelx_value('F', row)
      line.gross_amount   = BigDecimal(sheet.excelx_value('G', row))
      line.discount_taken = BigDecimal(sheet.excelx_value('L', row))
      line.paid_amount    = BigDecimal(sheet.excelx_value('R', row))

      row += 1
    end
    advice
  end

  def reconcile(advice)
    sum = advice.ips_payment_advice_lines.sum(BigDecimal("0.00")) { |l| l.paid_amount }
    unless sum == advice.total_amount
      raise "Total Amount does not match sum of lines: #{advice.total_amount} != #{sum}"
    end
  end


end


