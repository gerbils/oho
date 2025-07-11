require 'test_helper'
require 'bigdecimal'

class IpsPaymentReconcileTest < ActiveSupport::TestCase

  test "matches a single detail" do
    detail = create(:ips_statement_detail, month_due: "2025-05-15", due_this_month: BigDecimal("100.00"))
    payment_line = create(:ips_payment_advice_line, invoice_date: "2025-05-20", paid_amount: BigDecimal("100.00"))
    Royalties::Ips::ReconcilePayments.reconcile_line(payment_line)
    detail.reload
    payment_line.reload
    assert payment_line.reconciled?, "Payment line should be reconciled"
    assert_equal detail, payment_line.ips_statement_detail, "Payment line should be linked to detail"

  end
end
