# == Schema Information
#
# Table name: ips_statement_details
#
#  id                     :bigint           not null, primary key
#  basis                  :string(255)
#  basis_for_charge       :decimal(12, 4)   not null
#  detail                 :string(255)      not null
#  due_this_month         :decimal(12, 4)   not null
#  factor_or_rate         :decimal(6, 4)    not null
#  ips_detail_lines_count :integer          default(0), not null
#  month_due              :date
#  reconciled             :boolean          default(FALSE)
#  section                :string(255)      not null
#  subsection             :string(255)      not null
#  uploaded_at            :datetime
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  ips_statement_id       :bigint           not null
#  upload_wrapper_id      :bigint
#
# Indexes
#
#  index_ips_statement_details_on_ips_statement_id   (ips_statement_id)
#  index_ips_statement_details_on_upload_wrapper_id  (upload_wrapper_id)
#
# Foreign Keys
#
#  fk_rails_...  (ips_statement_id => ips_statements.id)
#  fk_rails_...  (upload_wrapper_id => upload_wrappers.id)
#
require "test_helper"
require "pry"

class IpsStatementDetailTest < ActiveSupport::TestCase

  def make_detail(month_due, due_this_month: "0.00")
    stmt = ips_statement!({})
    stmt.save!
    detail = ips_statement_detail!(ips_statement: stmt, month_due:, due_this_month:)
    detail.save!
    detail
  end

  test "date due is normalized to first of month" do
    assert_equal Date.new(2024, 5, 1), make_detail(Date.new(2024, 5, 15)).month_due
  end

  test "date due is unchanged if first of month" do
    assert_equal Date.new(2024, 5, 1), make_detail(Date.new(2024, 5, 1)).month_due
  end

  # test reconcilkiation of combos of multiple details against a single sum

  def combo_test(detail_amounts, target_sum, expected_count)
    details = detail_amounts.map { |amt| make_detail(Date.new(2024, 5, 1), due_this_month: amt) }
    matches = IpsStatementDetail.look_for_combinations(details, BigDecimal("350.00"))
    assert_equal expected_count, matches.length
    target = BigDecimal(target_sum)
    matches.each do |match|
      assert_equal target, match.sum(&:due_this_month)
    end
  end

  test "Simple combo of 2 details matches" do
    combo_test(%w{ 100.00 250.00 }, "350.00", 1)
  end

  test "Simple combo of 2 details matches regardless of order" do
    combo_test(%w{ 250.00 100.00 }, "350.00", 1)
  end

  test "Finds a combo of 2 in 4 details" do
    combo_test(%w{ 100.00 200.00 250.00 275.00 }, "350.00", 1)
  end

  test "Finds a combo of 3 in 4 details" do
    combo_test(%w{ 100.00 200.00 275.00 50.00 }, "350.00", 1)
  end

  test "Finds a combo of 3 in 4 details where a value is negative" do
    combo_test(%w{ 100.00 200.00 275.00 -25.00 }, "350.00", 1)
  end

  test "Find two combo of 2 in 4 details" do
    combo_test(%w{ 100.00 400.00 250.00 -50.00 }, "350.00", 2)
  end

  test "Find no combos in empty list" do
    combo_test(%w{}, "0", 0)
  end

end


