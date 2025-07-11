require "test_helper"
require "pry"

class IpsStatementDetailTest < ActiveSupport::TestCase

  test "date due is normalized to first of month" do
    stmt = create(:ips_statement_detail, month_due: Date.new(2024, 5, 15))
    assert_equal Date.new(2024, 5, 1), stmt.month_due
  end

  test "date due is unchanged if first of month" do
    stmt = create(:ips_statement_detail, month_due: Date.new(2024, 5, 1))
    assert_equal Date.new(2024, 5, 1), stmt.month_due
  end
end


