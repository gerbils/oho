require 'test_helper'
require 'bigdecimal'

class IpsUploadRollupTest < ActiveSupport::TestCase

  def sheet(name)
    File.read(File.join("test/fixtures/files/royalties", "#{name}.xlsx"))
  end

  def parse(sheet)
    s = IpsStatement.new
    Royalties::Ips::ParseDetailLines.parse(s, sheet(sheet), "xlsx")
  end

  def assert_equal?(expected, actual, message = nil)
    if expected.nil?
      assert_nil actual, message || "Both values are nil"
    else
      assert_equal expected, actual, message || "Expected #{expected.inspect}, got #{actual.inspect}"
    end
  end


  def assert_parse(sheet_name, expected_lines)
    lines = parse(sheet_name)
    assert_equal expected_lines.size, lines.size, "Expected #{expected_lines.size} lines, got #{lines.size}"
    expected_lines.zip(lines).each do |expected, got|
      assert_equal? expected[:ean], got.ean, "EAN mismatch for #{expected[:title]}"
      assert_equal expected[:content_type], got.content_type, "Content type mismatch for #{expected[:title]}"
      assert_equal? expected[:title], got.title, "Title mismatch for #{expected[:title]}"
      assert_equal expected[:description], got.description, "Description mismatch for #{expected[:title]}"
      assert_equal expected[:quantity], got.quantity, "Quantity mismatch for #{expected[:title]}"
      assert_equal BigDecimal(expected[:amount]), got.amount, "Amount mismatch for #{expected[:title]}"
    end
  end
  # def assert_line(expected, line)
  #   assert_equal(expected[:isbn], line.isbn, "ISBN mismatch")
  #   if expected[:e_isbn].nil?
  #     assert_nil(line.e_isbn, "eISBN should be nil")
  #   else
  #     assert_equal(expected[:e_isbn], line.e_isbn)
  #   end
  #   assert_equal(expected[:title], line.title, "Title mismatch")
  #   assert_equal('CDA_The Pragmatic Programmers, LLC', line.publisher, "Publisher mismatch")
  #   assert_equal(expected[:author], line.author, "Author mismatch")
  #   assert_equal(expected[:sales], line.sales, "Sales mismatch")
  #   assert_equal(expected[:commission_earned], line.commission_earned, "Commission Earned mismatch")
  #   assert_equal(expected[:commission_rate], line.commission_rate, "Commission Rate mismatch")
  # end
  #
  # def assert_lines(expected_lines, actual_lines)
  #   actual_lines = actual_lines.sort_by(&:sales)
  #   assert_equal(expected_lines.size, actual_lines.size, "Number of lines mismatch")
  #   expected_lines.each_with_index do |expected, index|
  #     actual = actual_lines[index]
  #     assert_line(expected, actual)
  #   end
  # end
  #
  # def assert_bad_header(col, expected_header)
  #   s = LpStatement.new
  #   error = assert_raises(RuntimeError) do
  #     Royalties::Lp::ParseStatement.parse(s, sheet("lp-bad-header-#{col}.xlsx"), "xlsx")
  #   end
  #   assert_match(/\^#{expected_header}\$/, error.message)
  # end
  #
  # def assert_bad_parse(file, message)
  #   s = LpStatement.new
  #   error = assert_raises(StandardError) do
  #     Royalties::Lp::ParseStatement.parse(s, sheet(file), "xlsx")
  #   end
  #   assert_match(message,  error.message)
  # end

  test "detects type 1 files" do
    assert_parse("ips_type_1_ok", [
      { ean: "9798888651049",
        content_type: "freight",
        title: "Agile Web Development with Rails 7.2",
        description: "Freight",
        quantity: 0,
        amount: "-3.3128",
      },
    ])
  end

  test "detects type 2 files" do
    assert_parse("ips_type_2_ok", [
      { ean: "9798888651049",
        content_type: "expense1",
        title: "Agile Web Development with Rails 7.2",
        description: "Distribution fee",
        quantity: 1,
        amount: "-9.2757",
      },
    ])
  end

  test "detects type 3 files" do
    assert_parse("ips_type_3_ok", [
      { ean: nil,
        content_type: "df_expense",
        title: nil,
        description: "Direct Fulfillment",
        quantity: 1,
        amount: "-3.84",
      },
    ])
  end

  test "detects type 4 files" do
    assert_parse("ips_type_4_ok", [
      { ean: "9781934356456",
        content_type: "lsi_expense",
        title: "Language Implementation Patterns : Create Your Own Domain-Specific and General Programming Languages",
        description: "Drop Ship",
        quantity: 1,
        amount: "-7.64",
      },
    ])
  end

  test "detects type 5 files" do
    assert_parse("ips_type_5_ok", [
      { ean: nil,
        content_type: "misc_expense",
        title: nil,
        description: "Amazon Freight- March",
        quantity: 0,
        amount: "-279.49",
      },
    ])
  end

  test "detects revenue files" do
    assert_parse("ips_revenue_ok", [
      { ean: "9798888651049",
        content_type: "all_revenues",
        title: "Agile Web Development with Rails 7.2",
        description: "Revenue",
        quantity: 1,
        amount: "44.17",
      },
    ])
  end

  # test "detects bad subtitle" do
  #   assert_bad_parse("lp-bad-subtitle.xlsx", /Expected .+O'Reilly Media, Inc/)
  # end
  #
  # test "detects bad statement_date" do
  #   assert_bad_parse("lp-bad-statement-date.xlsx", /Expected .+Statement Date/)
  # end
  #
  # test "detects bad statement_period" do
  #   assert_bad_parse("lp-bad-statement-period.xlsx", /Expected Statement Period/)
  # end
  #
  # test "detects bad column headers" do
  #   assert_bad_header(1, "ISBN")
  #   assert_bad_header(2, "eISBN")
  #   assert_bad_header(3, "Title")
  #   assert_bad_header(4, "Publisher")
  #   assert_bad_header(5, "Author")
  #   assert_bad_header(6, "Channel")
  #   assert_bad_header(7, "Sales")
  #   assert_bad_header(8, "Commission Rate")
  #   assert_bad_header(9, "Commission Earned")
  # end
  #
  # test "detects incorrect payment due" do
  #   assert_bad_parse("lp-bad-payment-due.xlsx", /\(10.68\) does not agree with batch total \(10.67\)/)
  # end
  #
  # test "detects bad format payment due" do
  #   assert_bad_parse("lp-bad-format-payment-due.xlsx", /invalid value for BigDecimal/)
  # end
  #
end
