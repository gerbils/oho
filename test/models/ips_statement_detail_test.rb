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

  test "date due is normalized to first of month" do
    stmt = ips_statement_detail!(month_due: Date.new(2024, 5, 15))
    stmt.save!
    assert_equal Date.new(2024, 5, 1), stmt.month_due
  end

  test "date due is unchanged if first of month" do
    stmt = ips_statement_detail!(month_due: Date.new(2024, 5, 1))
    stmt.save!
    assert_equal Date.new(2024, 5, 1), stmt.month_due
  end
end


