require "test_helper"

class IpsPaymentMatchTest < ActionDispatch::IntegrationTest

  setup do
    user = User.create!(email: "match-test@example.com", password: "password123", password_confirmation: "password123")
    post session_path, params: { email: user.email, password: "password123" }

    @earlier = ips_statement!({ month_ending: "2025-02-28" }).tap(&:save!)
    @current = ips_statement!({ month_ending: "2025-03-31" }).tap(&:save!)
    @late1 = ips_statement_detail!({ ips_statement: @earlier, detail: "Late co-op", due_this_month: BigDecimal("100.00") }).tap(&:save!)
    @late2 = ips_statement_detail!({ ips_statement: @earlier, detail: "Late freight", due_this_month: BigDecimal("150.00") }).tap(&:save!)
    @now   = ips_statement_detail!({ ips_statement: @current, detail: "This month", due_this_month: BigDecimal("75.00") }).tap(&:save!)

    @advice = ips_payment_advice!({ status: IpsPaymentAdvice::STATUS_PARTIALLY_RECONCILED }).tap(&:save!)
    @line = ips_payment_advice_line!({ ips_payment_advice: @advice, invoice_date: "2025-03-31", paid_amount: BigDecimal("250.00") }).tap(&:save!)
  end

  test "the payment page offers a search button for unreconciled lines" do
    get royalties_ips_payment_path(@advice)
    assert_response :success
    assert_select "a[href='#{match_line_royalties_ips_payment_path(@advice, line_id: @line.id)}'][data-turbo-frame='modal']"
  end

  test "shows the invoice month by default, and can page to an earlier month" do
    get match_line_royalties_ips_payment_path(@advice, line_id: @line.id)
    assert_response :success
    assert_select "turbo-frame#modal"
    assert_select "td", text: "This month"
    assert_select "td", text: "Late co-op", count: 0
    assert_select "a", text: /Feb 2025/

    get match_line_royalties_ips_payment_path(@advice, line_id: @line.id, month: "2025-02-28")
    assert_select "td", text: "Late co-op"
    assert_select "td", text: "Late freight"
  end

  test "applying details that total the payment reconciles the line" do
    post apply_match_royalties_ips_payment_path(@advice, line_id: @line.id),
         params: { detail_ids: [@late1.id, @late2.id] }, as: :turbo_stream
    assert_response :success
    assert_match %r{<turbo-stream action="replace" target="#{ActionView::RecordIdentifier.dom_id(@line)}">}, response.body
    assert @line.reload.reconciled?
    assert @late1.reload.reconciled
    assert_equal IpsPaymentAdvice::STATUS_RECONCILED, @advice.reload.status
  end

  test "applying details with the wrong total shows an error" do
    post apply_match_royalties_ips_payment_path(@advice, line_id: @line.id),
         params: { detail_ids: [@late1.id, @now.id] }
    assert_response :unprocessable_entity
    assert_select ".alert-danger", text: /total 175.0, not 250.0/
    refute @line.reload.reconciled?
  end
end
