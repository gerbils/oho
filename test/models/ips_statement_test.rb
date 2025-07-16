# == Schema Information
#
# Table name: ips_statements
#
#  id                          :bigint           not null, primary key
#  expenses                    :decimal(12, 4)   default(0.0)
#  gross_returns_total         :decimal(12, 4)   default(0.0)
#  gross_sales_total           :decimal(12, 4)   default(0.0)
#  import_free_units           :integer          default(0)
#  import_paid_amount          :decimal(12, 4)   default(0.0)
#  import_paid_units           :integer          default(0)
#  import_return_amount        :decimal(12, 4)   default(0.0)
#  import_return_units         :integer          default(0)
#  imported_at                 :datetime
#  ips_statement_details_count :integer          default(0)
#  month_ending                :date             default(Mon, 01 Jan 1000)
#  net_client_earnings         :decimal(12, 4)   default(0.0)
#  net_sales                   :decimal(12, 4)   default(0.0)
#  revenue                     :decimal(12, 4)   default(0.0)
#  status                      :string(255)      not null
#  status_message              :string(255)
#  total_chargebacks           :decimal(12, 4)   default(0.0)
#  total_expenses              :decimal(12, 4)   default(0.0)
#  created_at                  :datetime         not null
#  updated_at                  :datetime         not null
#  upload_wrapper_id           :bigint           not null
#
# Indexes
#
#  index_ips_statements_on_upload_wrapper_id  (upload_wrapper_id)
#
# Foreign Keys
#
#  fk_rails_...  (upload_wrapper_id => upload_wrappers.id)
#
require "test_helper"
require "pry"

class IpsStatementTest < ActiveSupport::TestCase

  # def mock_statement(net_client_earnings)
  #   statement = ips_statement!(net_client_earnings:)
  #   statement.save!
  #   statement
  # end
  #
  # def mock_detail(**args)
  #   ips_statement_detail!(**args)
  # end
  #
  # def mock_line(ean: "12345", title: "Test Book", **args)
  #   ips_detail_line!(**args, ean:, title:)
  # end
  #
  # def mock_upload_wrapper
  #   uw = upload_wrapper!
  #   uw
  # end
  #
  # def build_statement(net, details)
  #   statement = mock_statement(net)
  #   statement.save!
  #   details.each {|detail| statement.details << detail }
  #   statement.save || flunk(statement.errors.full_messages.to_sentence)
  #   statement
  # end
  #
  # def detail(section, subsection, detail, gross, rate, due, lines)
  #   detail = mock_detail(section:, subsection:, detail:, basis_for_charge: gross, factor_or_rate: rate, due_this_month: due)
  #   detail.save!
  #   lines.each {|line| detail.ips_detail_lines << line }
  #   detail
  # end
  #
  # def line(sku, content_type, description, quantity, amount)
  #   mock_line(sku:, content_type:, description:, quantity:, amount:)
  # end
  #
  # ######################################################################
  # def assert_line_matches(statement_id, exp, line)
  #    m = -> (msg) { "#{exp[0]}: #{msg}" }
  #     if exp[0]
  #       binding.pry if skus(exp[0]).id != line.sku_id
  #       assert_equal skus(exp[0]).id, line.sku_id, m["SKU ID should match"]
  #     else
  #       assert_nil(line.sku_id, m["SKU ID should be nil"])
  #     end
  #     assert_equal exp[1], line.item_type
  #     assert_equal exp[2], line.description
  #     assert_equal exp[3], line.free_units,    m["Free units should be zero"]
  #     assert_equal exp[4], line.paid_units,    m["Paid units should match quantity"]
  #     assert_equal exp[5], line.paid_amount,   m["Paid amount should match line amount"]
  #     assert_equal exp[6], line.return_units,  m["Return units should match"]
  #     assert_equal exp[7], line.return_amount, m["Return amount should match"]
  #     assert_equal exp[8], line.date.strftime('%Y-%m-%d'), m["Date should match month ending"]
  #     assert_equal RoyaltyItem::APPLIES_TO_BOTH, line.applies_to, m["Applies to should be both"]
  #     assert_equal IpsStatement.name, line.source_type, m["Source type should be IpsStatement"]
  #     assert_equal statement_id, line.source_id, m["Source ID should match statement ID"]
  # end
  #

  ######################################################################

  test "should be valid with all attributes" do
    statement = ips_statement!({})
    assert statement.valid?
  end

  ######################################################################

end
