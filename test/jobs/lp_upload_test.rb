require 'bigdecimal'

class LpUploadTest < ActiveSupport::TestCase

  def sheet(name)
    File.read(File.join("test/fixtures/files/royalties", name))
  end

  def assert_line(expected, line)
    assert_equal(expected[:isbn], line.isbn, "ISBN mismatch")
    if expected[:e_isbn].nil?
      assert_nil(line.e_isbn, "eISBN should be nil")
    else
      assert_equal(expected[:e_isbn], line.e_isbn)
    end
    assert_equal(expected[:title], line.title, "Title mismatch")
    assert_equal('CDA_The Pragmatic Programmers, LLC', line.publisher, "Publisher mismatch")
    assert_equal(expected[:author], line.author, "Author mismatch")
    assert_equal(expected[:sales], line.sales, "Sales mismatch")
    assert_equal(expected[:commission_earned], line.commission_earned, "Commission Earned mismatch")
    assert_equal(expected[:commission_rate], line.commission_rate, "Commission Rate mismatch")
  end

  def assert_lines(expected_lines, actual_lines)
    actual_lines = actual_lines.sort_by(&:sales)
    assert_equal(expected_lines.size, actual_lines.size, "Number of lines mismatch")
    expected_lines.each_with_index do |expected, index|
      actual = actual_lines[index]
      assert_line(expected, actual)
    end
  end

  def assert_bad_header(col, expected_header)
    s = LpStatement.new
    result = Royalties::Lp::ParseStatement.parse(s, sheet("lp-bad-header-#{col}.xlsx"), "xlsx")
    assert_equal(:error, result[:status])
    assert_match(/\^#{expected_header}\$/, result[:message])
  end

  test "detects bad title" do
    s = LpStatement.new
    result = Royalties::Lp::ParseStatement.parse(s, sheet("lp-no-title.xlsx"), "xlsx")
    assert_equal(:error, result[:status])
    assert_match(/Expected Statement Header but got "O'Reilly Quarterly Commission Statement Error"/,  result[:message])
  end

  test "detects bad subtitle" do
    s = LpStatement.new
    result = Royalties::Lp::ParseStatement.parse(s, sheet("lp-bad-subtitle.xlsx"), "xlsx")
    assert_equal(:error, result[:status])
    assert_match(/Expected .+O'Reilly Media, Inc/, result[:message])
  end

  test "detects bad statement_date" do
    s = LpStatement.new
    result = Royalties::Lp::ParseStatement.parse(s, sheet("lp-bad-statement-date.xlsx"), "xlsx")
    assert_equal(:error, result[:status])
    assert_match(/Expected .+Statement Date/, result[:message])
  end

  test "detects bad statement_period" do
    s = LpStatement.new
    result = Royalties::Lp::ParseStatement.parse(s, sheet("lp-bad-statement-period.xlsx"), "xlsx")
    assert_equal(:error, result[:status])
    assert_match(/Expected Statement Period/, result[:message])
  end

  test "detects bad column headers" do
    assert_bad_header(1, "ISBN")
    assert_bad_header(2, "eISBN")
    assert_bad_header(3, "Title")
    assert_bad_header(4, "Publisher")
    assert_bad_header(5, "Author")
    assert_bad_header(6, "Channel")
    assert_bad_header(7, "Sales")
    assert_bad_header(8, "Commission Rate")
    assert_bad_header(9, "Commission Earned")
  end

  test "detects incorrect payment due" do
    s = LpStatement.new
    result = Royalties::Lp::ParseStatement.parse(s, sheet("lp-bad-payment-due.xlsx"), "xlsx")
    assert_equal(:error, result[:status])
    assert_match(/\(10.68\) does not agree with batch total \(10.67\)/, result[:message])
  end

  test "detects bad format payment due" do
    s = LpStatement.new
    result = Royalties::Lp::ParseStatement.parse(s, sheet("lp-bad-format-payment-due.xlsx"), "xlsx")
    assert_equal(:error, result[:status])
    assert_match(/invalid value for BigDecimal/, result[:message])
  end

end
