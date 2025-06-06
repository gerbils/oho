require 'roo'
require 'bigdecimal'


module Royalties::Ips::ParseStatement
  extend self
  extend Royalties::Shared

  def parse_statement(content)
    sheet = open_spreadsheet(content, 'xlsx')
    report = IpsStatement.new
    report = validate_expected_format(sheet, report)
    report = split_rows(report, sheet)
    reconcile(report)
    { status: :ok, statement: report }
  # rescue => e
  #   { status: :error, message: e.message }
  end

  private

  def row_error(row, cell, expected)
    row_number = cell.coordinate.first
    col_number = cell.coordinate.last
    msg = [
      "On row     #{row_number}, column #{col_number}:",
      "Expected   #{expected.inspect}, got #{cell.value.inspect}",
      "Whole row: #{row.map(&:cell_value).inspect}"
    ]
    raise msg.join("\n")
  end

  def check_cell(sheet, row, col, value)
    cell_value = sheet.cell(row, col)
    row_error(sheet.row(row), sheet.cell(row, col), value) unless cell_value == value
  end


  def validate_expected_format(sheet, report)
    raise 'Unexpected first row/column' unless sheet.first_row == 1 && sheet.first_column == 1
    check_cell(sheet, 1, 1, "PRAGMATIC PROGRAMMERS LLC")
    check_cell(sheet, 2, 1, "Client Statement")
    date = sheet.cell(3, 1)
    if date !~ /Month Ending (\w+ \d{1,2}(?:th|st), \d{4})/
      row_error(sheet.row(3), sheet.cell(3, 1), "Month Ending Month Day, Year")
    end
    date = $1
    date = Date.parse($1) rescue raise("Invalid date: #{date}")
    report.month_ending = date
    report
  end

  EXPECTED_SALES_HEADER = [ nil, nil, "Basis", "Basis for Charge", "Factor / Rate", "Amount Due This Month" ]
  def check_sales_header(row, expected_header)
    cells = row.map(&:cell_value)
    unless cells == EXPECTED_SALES_HEADER
      raise "Expected header for #{expected_header}, got #{cells.inspect}"
    end
  end

  EXPECTED_EXPENSES_HEADER = [ nil, "Month Due", "Basis", "Basis for Charge", "Factor / Rate", "Amount Due This Month" ]
  def check_expenses_header(row, expected_header)
    cells = row.map(&:cell_value)
    unless cells == EXPECTED_EXPENSES_HEADER
      raise "Expected header for #{expected_header}, got #{cells.inspect}"
    end
  end

  def split_rows(report, sheet)
    state = :looking_for_gross_sales
    expense_type = ""
    subsection = ""

    sheet.each_row_streaming(offset: 1) do |row|
      case state
      when :looking_for_gross_sales
        if row[0].cell_value == "Gross Sales"
          state = :check_gross_sales_header
        end

      when :check_gross_sales_header
        check_sales_header(row, "Gross Sales")
        state = :reading_revenue

      when :reading_revenue
        label            = row[0].cell_value
        if label.nil? || label.strip.empty?
          unless row[4].cell_value == "Total"
            row_error(row, row[4], 'Total')
          end
          report.gross_sales_total = BigDecimal(row[5].cell_value)
          state = :looking_for_returns
        else
          basis_for_charge = BigDecimal(row[3].cell_value)
          factor_rate      = BigDecimal(row[4].cell_value)
          amount_due       = BigDecimal(row[5].cell_value)
          report.revenues.new({
            section: IpsStatementDetail::SECTION_REVENUE,
            subsection: "Gross Sales",
            detail: label,
            month_due: nil,
            basis_for_charge: basis_for_charge, factor_or_rate: factor_rate, due_this_month: amount_due
          })
        end

      when :looking_for_returns
        if row[0].cell_value == "Returns"
          state = :check_returns_header
        else
          row_error(row, row[0], "Returns")
        end

      when :check_returns_header
        check_sales_header(row, "Returns")
        state = :reading_returns

      when :reading_returns
        label            = row[0].cell_value
        if label.nil? || label.strip.empty?
          unless row[4].cell_value == "Total"
            row_error(row, row[4], 'Total')
          end
          report.gross_returns_total = BigDecimal(row[5].cell_value)
          state = :looking_for_net_sales
        else
          basis_for_charge = BigDecimal(row[3].cell_value)
          factor_rate      = BigDecimal(row[4].cell_value)
          amount_due       = BigDecimal(row[5].cell_value)
          report.revenues.new({
            section: IpsStatementDetail::SECTION_REVENUE,
            subsection: "Returns",
            detail: label,
            month_due: nil,
            basis_for_charge: basis_for_charge, factor_or_rate: factor_rate, due_this_month: amount_due
          })
        end

      when :looking_for_net_sales
        unless row[4].cell_value == "Net Sales"
          row_error(row, row[4], 'Net Sales')
        end
        report.net_sales = BigDecimal(row[5].cell_value)
        state = :looking_for_expenses

      when :looking_for_expenses
        unless row[0].cell_value == "EXPENSES"
          row_error(row, row[0], 'EXPENSES')
        end
        state = :expenses_block

      when :expenses_block
        expense_type = row[0].cell_value
        if expense_type.nil? || expense_type.strip.empty?
          unless row[3].cell_value == "Total Chargebacks"
            row_error(row, row[3], 'Total Chargebacks')
          end
          report.total_chargebacks = BigDecimal(row[5].cell_value)
          state = :collect_total_expenses
        else
          subsection = row[0].cell_value
          state = :check_expenses_header
        end

      when :check_expenses_header
        check_expenses_header(row, expense_type)
        state = :reading_expenses

      when :reading_expenses
        kind = row[0].cell_value
        if kind.nil? || kind.strip.empty?
          unless row[3].cell_value == "Total"
            row_error(row, row[3], "Total")
          end
          state = :expenses_block
        else
          month_due = Date.parse(row[1].cell_value)
          basis = row[2].cell_value
          basis_for_charge = BigDecimal(row[3].cell_value)
          factor_rate = BigDecimal(row[4].cell_value)
          amount_due = BigDecimal(row[5].cell_value)
          report.expenses.new({
            section: IpsStatementDetail::SECTION_EXPENSE,
            subsection: subsection,
            detail: kind,
            month_due: month_due,
            basis: basis,
            basis_for_charge: basis_for_charge, factor_or_rate: factor_rate, due_this_month: amount_due
          })
        end

      when :collect_total_expenses
        unless row[3].cell_value == "Total Expenses"
          row_error(row, row[3], 'Total Expenses')
        end
        report.total_expenses = BigDecimal(row[5].cell_value)
        state = :collect_net_client_earnings

      when :collect_net_client_earnings
        unless row[3].cell_value == "Net Client Earnings"
          row_error(row, row[3], 'Net Client Earnings')
        end
        report.net_client_earnings = BigDecimal(row[5].cell_value)
        state = :done

      when :done
        pp report
        break

      else
        raise "bad state parsing statement: #{state.inspect}"
      end

    end

    report
  end

  def reconcile(report)
    rev_sum = report.revenues.sum(BigDecimal("0.00")) { |r| r.due_this_month }
    unless report.net_sales == rev_sum
      raise "Net Sales total does not match sum of revenue: #{report.net_sales} != #{rev_sum}"
    end
    unless report.net_sales = report.gross_sales_total + report.gross_returns_total
      raise "Net Sales does not match Gross Sales - Returns: #{report.net_sales} != #{report.gross_sales_total} - #{report.gross_returns_total}"
    end
    exp_sum = report.expenses.sum(BigDecimal("0.00")) { |e| e.due_this_month }
    unless report.total_expenses == exp_sum
      raise "Total Expenses does not match sum of expenses: #{report.total_expenses} != #{exp_sum}"
    end
    unless report.net_client_earnings == (report.net_sales + report.total_expenses)
      raise "Net Client Earnings does not match Net Sales - Total Expenses: #{report.net_client_earnings} != #{report.net_sales}#{report.total_expenses}-#{report.total_chargebacks}"
    end
  end


end


