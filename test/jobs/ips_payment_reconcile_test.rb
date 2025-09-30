require 'test_helper'
require 'bigdecimal'
require 'pry'

class IpsPaymentReconcileTest < ActiveSupport::TestCase

  def assert_reconciles(detail_attrs, payment_line_attrs)
    statement_date = detail_attrs.shift
    statement = ips_statement!({ month_ending: statement_date })
    statement.save!
    details = detail_attrs.map { |attrs| ips_statement_detail!({ips_statement: statement}.merge(attrs)) }
    details.each(&:save!)

    advice = ips_payment_advice!
    payment_lines = payment_line_attrs.map { |attrs| ips_payment_advice_line!({ips_payment_advice: advice}.merge(attrs)) }
    payment_lines.each(&:save!)

    payment_lines.each do |line|
      Royalties::Ips::ReconcilePayments.reconcile_line(line)
    end
    details.each(&:reload)
    payment_lines.each(&:reload)
    yield(details, payment_lines) if block_given?
  end

  test "matches a single detail" do
    details       = [
      "2025-03-31",
      { month_due: "2025-05-31", due_this_month: BigDecimal("100.00") }
    ]
    payment_lines = [
      { invoice_date: "2025-05-20", paid_amount: BigDecimal("100.00") }
    ]
    assert_reconciles(details, payment_lines) do |details, payment_lines|
      assert payment_lines[0].reconciled?, "Payment line should be reconciled"
      assert_equal details[0], payment_lines[0].ips_statement_details[0], "Payment line should be linked to detail"
    end
  end

  test "matches one out of two details with same month but different amount" do
    details = [
      "2025-03-31",
      { month_due: "2025-05-15", due_this_month: BigDecimal("200.00") },
      { month_due: "2025-05-15", due_this_month: BigDecimal("100.00") },
    ]
    payment_lines = [
      { invoice_date: "2025-05-20", paid_amount: BigDecimal("100.00") },
    ]
    assert_reconciles(details, payment_lines) do |details, payment_lines|
      assert payment_lines[0].reconciled?, "Payment line should be reconciled"
      assert_equal details[1], payment_lines[0].ips_statement_details[0], "Payment line should be linked to detail"
    end
  end

  test "matches one out of two details with different month but same amount" do
    details = [
      "2025-03-31",
      { month_due: "2025-05-15", due_this_month: BigDecimal("100.00") },
      { month_due: "2025-04-15", due_this_month: BigDecimal("100.00") },
    ]
    payment_lines = [
      { invoice_date: "2025-05-20", paid_amount: BigDecimal("100.00") },
    ]
    assert_reconciles(details, payment_lines) do |details, payment_lines|
      assert payment_lines[0].reconciled?, "Payment line should be reconciled"
      assert_equal details[0], payment_lines[0].ips_statement_details[0], "Payment line should be linked to detail"
    end
  end

  test "two payments match two details" do
    details = [
      "2025-03-31",
      { month_due: "2025-05-15", due_this_month: BigDecimal("200.00") },
      { month_due: "2025-05-15", due_this_month: BigDecimal("100.00") },
    ]
    payment_lines = [
      { invoice_date: "2025-05-20", paid_amount: BigDecimal("100.00") },
      { invoice_date: "2025-05-10", paid_amount: BigDecimal("200.00") },
    ]
    assert_reconciles(details, payment_lines) do |details, payment_lines|
      assert payment_lines[0].reconciled?, "Payment line should be reconciled"
      assert payment_lines[1].reconciled?, "Payment line should be reconciled"
      assert_equal details[1], payment_lines[0].ips_statement_details[0], "Payment line should be linked to detail"
      assert_equal details[0], payment_lines[1].ips_statement_details[0], "Payment line should be linked to detail"
    end
  end


  test "fails to match if details wrong" do
    details       = [ "2025-03-31", { month_due: "2025-05-15", due_this_month: BigDecimal("100.99") } ]
    payment_lines = [ { invoice_date: "2025-03-31", paid_amount: BigDecimal("100.00") } ]
    assert_reconciles(details, payment_lines) do |details, payment_lines|
      refute payment_lines[0].reconciled?, "Payment line should be reconciled"
      assert_equal 0, payment_lines[0].ips_statement_details.count, "No detail is linked"
    end
  end

  test "doesn't match a second payment to the same detail as the first" do
    details       = [ "2025-03-31", { month_due: "2025-05-15", due_this_month: BigDecimal("100.00") } ]
    payment_lines = [
      { invoice_date: "2025-03-31", paid_amount: BigDecimal("100.00") },
      { invoice_date: "2025-03-31", paid_amount: BigDecimal("100.00") },
    ]
    assert_reconciles(details, payment_lines) do |details, payment_lines|
      assert payment_lines[0].reconciled?, "Payment line should be reconciled"
      assert_equal details[0], payment_lines[0].ips_statement_details[0], "Payment line should be linked to detail"
      refute payment_lines[1].reconciled?, "The second payment line should not be reconciled"
      assert_equal 0,payment_lines[1].ips_statement_details.count, "And no detail is linked"
    end
  end

  test "matches when a payment matches the sum of two detail" do
    details       = [
      "2025-03-31",
      { month_due: "2025-05-15", due_this_month: BigDecimal("100.00") },
      { month_due: "2025-05-15", due_this_month: BigDecimal("200.00") },
    ]
    payment_lines = [
      { invoice_date: "2025-03-31", paid_amount: BigDecimal("300.00") },
    ]
    assert_reconciles(details, payment_lines) do |details, payment_lines|
      assert payment_lines[0].reconciled?, "Payment line should be reconciled"
      assert_equal details[0], payment_lines[0].ips_statement_details[0], "Payment line should be linked to detail"
      assert_equal details[1], payment_lines[0].ips_statement_details[1], "Payment line should be linked to detail"
    end
  end

  test "flags an error if multiple combinations match" do
    details       = [
      "2025-03-31",
      { month_due: "2025-05-15", due_this_month: BigDecimal("100.00") },
      { month_due: "2025-05-15", due_this_month: BigDecimal("200.00") },
      { month_due: "2025-05-15", due_this_month: BigDecimal("100.00") },
    ]
    payment_lines = [
      { invoice_date: "2025-03-31", paid_amount: BigDecimal("300.00") },
    ]
    assert_reconciles(details, payment_lines) do |details, payment_lines|
      refute payment_lines[0].reconciled?, "Payment line should not be reconciled"
      assert_equal "Too many matches", payment_lines[0].status, "Payment line should have an error status"
    end
  end

  test "flags an error if no combinations match" do
    details       = [
      "2025-03-31",
      { month_due: "2025-05-15", due_this_month: BigDecimal("100.00") },
      { month_due: "2025-05-15", due_this_month: BigDecimal("400.00") },
      { month_due: "2025-05-15", due_this_month: BigDecimal("100.00") },
    ]
    payment_lines = [
      { invoice_date: "2025-03-31", paid_amount: BigDecimal("300.00") },
    ]
    assert_reconciles(details, payment_lines) do |details, payment_lines|
      refute payment_lines[0].reconciled?, "Payment line should not be reconciled"
      assert_equal "Unreconciled", payment_lines[0].status, "Payment line should have an error status"
    end
  end

  test "finds the simple match in preference to s combination" do
    details       = [
      "2025-03-31",
      { month_due: "2025-05-15", due_this_month: BigDecimal("100.00") },
      { month_due: "2025-05-15", due_this_month: BigDecimal("200.00") },
      { month_due: "2025-05-15", due_this_month: BigDecimal("300.00") },
    ]
    payment_lines = [
      { invoice_date: "2025-03-31", paid_amount: BigDecimal("300.00") },
    ]
    assert_reconciles(details, payment_lines) do |details, payment_lines|
      assert payment_lines[0].reconciled?, "Payment line should be reconciled"
      assert_equal details[2], payment_lines[0].ips_statement_details[0], "Payment line should be linked to detail"
    end
  end


end
