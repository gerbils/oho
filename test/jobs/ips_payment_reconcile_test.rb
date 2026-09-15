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

  def manual_setup(amounts, paid_amount)
    statement = ips_statement!({ month_ending: "2025-02-28" })
    statement.save!
    details = amounts.map do |amount|
      ips_statement_detail!({ ips_statement: statement, due_this_month: BigDecimal(amount) }).tap(&:save!)
    end
    advice = ips_payment_advice!
    advice.save!
    line = ips_payment_advice_line!({ ips_payment_advice: advice, invoice_date: "2025-03-31", paid_amount: BigDecimal(paid_amount) })
    line.save!
    [details, line, advice]
  end

  test "manually reconciles a line with details that total its amount" do
    details, line, advice = manual_setup(%w[100.00 150.00 50.00], "250.00")
    Royalties::Ips::ReconcilePayments.reconcile_with_details(line, details[0..1])

    line.reload
    assert line.reconciled?
    assert_equal IpsPaymentAdviceLine::STATUS_RECONCILED, line.status
    assert_equal details[0..1].map(&:id).sort, line.ips_statement_details.map(&:id).sort
    assert details[0].reload.reconciled
    refute details[2].reload.reconciled
    assert_equal IpsPaymentAdvice::STATUS_RECONCILED, advice.reload.status
  end

  test "refuses a manual reconcile when the total doesn't match" do
    details, line, _ = manual_setup(%w[100.00 150.00], "200.00")
    assert_raises(Royalties::Ips::ReconcilePayments::ManualReconcileError) do
      Royalties::Ips::ReconcilePayments.reconcile_with_details(line, details)
    end
    refute line.reload.reconciled?
    refute details[0].reload.reconciled
  end

  test "refuses a manual reconcile using an already reconciled detail" do
    details, line, _ = manual_setup(%w[100.00 150.00], "250.00")
    details[0].update!(reconciled: true)
    assert_raises(Royalties::Ips::ReconcilePayments::ManualReconcileError) do
      Royalties::Ips::ReconcilePayments.reconcile_with_details(line, details)
    end
    refute line.reload.reconciled?
  end

  test "lists unreconciled details for the month" do
    details, line, _ = manual_setup(%w[100.00 150.00], "250.00")
    details[1].update!(reconciled: true)
    assert_equal [details[0]], IpsStatementDetail.unreconciled_for_month(Date.new(2025, 2, 10)).to_a
    assert_empty IpsStatementDetail.unreconciled_for_month(line.invoice_date).to_a
  end


end
