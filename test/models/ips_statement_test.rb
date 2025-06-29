require "test_helper"
require "pry"

class IpsStatementTest < ActiveSupport::TestCase

  @@id = 0

  def mock_statement(net)
    @@id += 1
    IpsStatement.new(
      id:                          @@id,
      upload_wrapper:              mock_upload_wrapper,
      status:                      IpsStatement::STATUS_UPLOADED,
      status_message:              nil,
      month_ending:                "2025-04-30",
      gross_sales_total:           500,
      gross_returns_total:         0,
      net_sales:                   500,
      total_chargebacks:           0,
      total_expenses:              0,
      net_client_earnings:         net,
      imported_at:                 nil,
      ips_statement_details_count: 0,
    )
  end

  def mock_detail(section:, subsection:, detail:, gross:, rate:, due:, ips_statement: nil, basis: nil)
    @@id += 1
    IpsStatementDetail.new(
      id: @@id,
      ips_statement:,
      uploaded_at: Time.now,
      section:,
      subsection:,
      detail:,
      month_due: "2025-04-01",
      basis: basis,
      basis_for_charge: gross,
      factor_or_rate: rate,
      due_this_month: due,
      created_at: "2025-06-15 18:04:38.403136000 +0000",
      updated_at: "2025-06-16 18:16:01.761187000 +0000")
  end

  def mock_line(content_type:, description:, quantity:, amount:, ean: "12345",
                sku:, title: "Test Book")
    @@id += 1
    IpsDetailLine.new(
      id: @@id,
      sku_id: sku ? skus(sku).id : nil,
      ean:,
      title:,
      content_type:,
      description:,
      quantity:,
      amount:,
      json: { dummy: 99 }
    )
  end

  def mock_upload_wrapper
    uw = UploadWrapper.new
    uw.file.attach(io: StringIO.new("mock file content"), filename: "mock_file.txt")
    uw
  end

  def build_statement(net, details)
    statement = mock_statement(net)
    details.each {|detail| statement.details << detail }
    statement.save || flunk(statement.errors.full_messages.to_sentence)
    statement
  end

  def detail(section, subsection, detail, gross, rate, due, lines)
    detail = mock_detail(section:, subsection:, detail:, gross:, rate:, due:)
    lines.each {|line| detail.ips_detail_lines << line }
    detail
  end

  def line(sku, content_type, description, quantity, amount)
    mock_line(sku:, content_type:, description:, quantity:, amount:)
  end

  ######################################################################
  def assert_line_matches(statement_id, exp, line)
     m = -> (msg) { "#{exp[0]}: #{msg}" }
      if exp[0]
        binding.pry if skus(exp[0]).id != line.sku_id
        assert_equal skus(exp[0]).id, line.sku_id, m["SKU ID should match"]
      else
        assert_nil(line.sku_id, m["SKU ID should be nil"])
      end
      assert_equal exp[1], line.item_type
      assert_equal exp[2], line.description
      assert_equal exp[3], line.free_units,    m["Free units should be zero"]
      assert_equal exp[4], line.paid_units,    m["Paid units should match quantity"]
      assert_equal exp[5], line.paid_amount,   m["Paid amount should match line amount"]
      assert_equal exp[6], line.return_units,  m["Return units should match"]
      assert_equal exp[7], line.return_amount, m["Return amount should match"]
      assert_equal exp[8], line.date.strftime('%Y-%m-%d'), m["Date should match month ending"]
      assert_equal RoyaltyItem::APPLIES_TO_BOTH, line.applies_to, m["Applies to should be both"]
      assert_equal IpsStatement.name, line.source_type, m["Source type should be IpsStatement"]
      assert_equal statement_id, line.source_id, m["Source ID should match statement ID"]
  end

  def assert_royalty_calculated(expected, statement)
    result = statement.statement_lines
    binding.pry if expected.size != result.size
    assert_equal expected.size, result.size, "calculated result size"
    expected.zip(result).each do |exp, line|
      assert_line_matches(statement.id, exp, line)
    end
  end

  def assert_royalty_lines_saved(expected, statement)
    Royalties::Ips::ImportHandler.import(statement)
    result = RoyaltyItem.all.order(:sku_id)
    assert_equal expected.size, result.size, "Expected #{expected.size} royalty lines, got #{result.size}"

    expected = expected.sort_by { |e| skus(e[0]).id }

    expected.zip(result).each do |exp, line|
      assert_line_matches(statement.id, exp, line)
    end
  end

  ######################################################################

  test "should be valid with all attributes" do
    statement = mock_statement(123)
    assert statement.valid?
  end

  ######################################################################

  test "statement with one detail and one line creates correct royalty line" do
    statement = build_statement(500,
      [ detail(IpsStatementDetail::SECTION_REVENUE, "Gross Sales", "Domestic Gross Sales Excluding Canada", 500, 1, 500,
          [ line(:trevan_b, "royalty", "Test Royalty", 2, 500), ])
      ]
    )

    expected = [
      [ :trevan_b, "IPS-R", "Distribution: Domestic Sales", 0, 2, 500, 0, 0, '2025-04-30', statement.id ],
    ]
    assert_royalty_calculated(expected, statement)
    assert_royalty_lines_saved(expected, statement)
  end

  ######################################################################

  test "statement with different total to sum(rls) fails" do
    statement = build_statement(300,
      [ detail(IpsStatementDetail::SECTION_REVENUE, "Gross Sales", "Domestic Gross Sales Excluding Canada", 300, 1, 300,
          [ line(:trevan_b, "royalty", "Test Royalty", 2, 500), ])
      ]
    )
    error = assert_raises(RuntimeError) do
      Royalties::Ips::ImportHandler.import(statement)
    end
    assert_match(%r[Net client earnings mismatch—\nstatement: \$300.00,\ncalculated: \$500.00]m, error.message)
  end

  ######################################################################

  test "statement with one detail and two lines for same sku creates correct royalty line" do
    statement = build_statement(500,
      [ detail(IpsStatementDetail::SECTION_REVENUE, "Gross Sales", "Domestic Gross Sales Excluding Canada", 500, 1, 500,
          [
            line(:trevan_b, "royalty", "Test Royalty", 2, 200),
            line(:trevan_b, "royalty", "Test Royalty", 3, 300),
          ])
      ]
    )

    expected = [
      [ :trevan_b, "IPS-R", "Distribution: Domestic Sales", 0, 5, 500, 0, 0, '2025-04-30', statement.id ],
    ]
    assert_royalty_calculated(expected, statement)
    assert_royalty_lines_saved(expected, statement)
  end

  ######################################################################

  test "statement with two details, one line each for same sku creates correct royalty line" do
    statement = build_statement(500,
      [
        detail(IpsStatementDetail::SECTION_REVENUE, "Gross Sales", "Domestic Gross Sales Excluding Canada", 200, 1, 200,
          [
            line(:trevan_b, "royalty", "Test Royalty", 2, 200),
          ]),
        detail(IpsStatementDetail::SECTION_REVENUE, "Gross Sales", "Ebook Sales Gross", 300, 3, 300,
          [
            line(:trevan_b, "royalty", "Test Royalty", 3, 300),
          ])
      ]
    )

    expected = [
      [ :trevan_b, "IPS-R", "Distribution: Domestic Sales", 0, 2, 200, 0, 0, '2025-04-30', statement.id ],
      [ :trevan_b, "IPS-R", "Distribution: Ebook Sales",    0, 3, 300, 0, 0, '2025-04-30', statement.id ],
    ]
    assert_royalty_calculated(expected, statement)
    assert_royalty_lines_saved(expected, statement)
  end


  ######################################################################

  test "statement with two details, one line each for different sku creates correct royalty line" do
    statement = build_statement(500,
      [
        detail(IpsStatementDetail::SECTION_REVENUE, "Gross Sales", "Domestic Gross Sales Excluding Canada", 200, 1, 200,
          [
            line(:trevan_b, "royalty", "Test Royalty", 2, 200),
          ]),
        detail(IpsStatementDetail::SECTION_REVENUE, "Gross Sales", "Ebook Sales Gross", 300, 3, 300,
          [
            line(:pg_git_b, "royalty", "Test Royalty", 3, 300),
          ])
      ]
    )

    expected = [
      [ :trevan_b, "IPS-R", "Distribution: Domestic Sales", 0, 2, 200, 0, 0, '2025-04-30', statement.id ],
      [ :pg_git_b, "IPS-R", "Distribution: Ebook Sales",    0, 3, 300, 0, 0, '2025-04-30', statement.id ],
    ]
    assert_royalty_calculated(expected, statement)
    assert_royalty_lines_saved(expected, statement)
  end

  ######################################################################

  test "statement with two details, one sale line and one return" do
    statement = build_statement(100,
      [
        detail(IpsStatementDetail::SECTION_REVENUE, "Gross Sales", "Domestic Gross Sales Excluding Canada", 100, 1, 100,
          [
            line(:trevan_b, "royalty", "Test Royalty", 2, 200),
          ]),
        detail(IpsStatementDetail::SECTION_REVENUE, "Returns", "Ebook Returns", 100, 1, 100,
          [
            line(:pg_git_b, "royalty", "Test Royalty", -1, -100),
          ])
      ]
    )

    expected = [
      [ :trevan_b, "IPS-R", "Distribution: Domestic Sales", 0, 2, 200, 0, 0, '2025-04-30', statement.id ],
      [ :pg_git_b, "IPS-R", "Distribution: Ebook Returns",  0, 0, 0, -1, -100, '2025-04-30', statement.id ],
    ]
    assert_royalty_calculated(expected, statement)
    assert_royalty_lines_saved(expected, statement)
  end


  ######################################################################

  test "expense categorization" do
    statement = build_statement(-1500,
      [
        detail(IpsStatementDetail::SECTION_EXPENSE, "Direct Fulfillment Freight & Handling Fees", "Direct Fulfillment Order Fees", -100, 1, -100,
          [
            line(:trevan_b, "expense", "Test expense", 1, -100),
          ]),
        detail(IpsStatementDetail::SECTION_EXPENSE, "DistributionFees", "Canadian Sales Gross", -200, 0, -200,
          [
            line(:pg_git_b, "expense", "Test expense", 0, -200),
          ]),
        detail(IpsStatementDetail::SECTION_EXPENSE, "Freight", "Direct Fulfillment Order Fees", -100, 1, -300,
          [
            line(:trevan_p, "expense", "Test expense", 1, -300),
          ]),
        detail(IpsStatementDetail::SECTION_EXPENSE, "Lightning Source Services", "LSI Charges Print to Order Printing", -400, 0, -400,
          [
            line(:pg_git_p, "expense", "Test expense", 0, -400),
          ]),
        detail(IpsStatementDetail::SECTION_EXPENSE, "Other fees", "Co-Op", -500, 1, -500,
          [
            line(:trevan_s, "expense", "Test expense", 0, -500),
          ]),
      ]
    )

    expected = [
      [ :trevan_b, "IPS-E", "Distribution: Fulfillment",       0, 0, 0, 1, -100, '2025-04-30', statement.id ],
      [ :pg_git_b, "IPS-E", "Distribution: Fees",              0, 0, 0, 0, -200, '2025-04-30', statement.id ],
      [ :trevan_p, "IPS-E", "Distribution: Fulfillment",       0, 0, 0, 1, -300, '2025-04-30', statement.id ],
      [ :pg_git_p, "IPS-E", "Printing costs",                  0, 0, 0, 0, -400, '2025-04-30', statement.id ],
      [ :trevan_s, "IPS-E", "Distribution: Marketing & Misc.", 0, 0, 0, 0, -500, '2025-04-30', statement.id ],
    ]
    assert_royalty_calculated(expected, statement)
    assert_royalty_lines_saved(expected, statement)
  end

  ######################################################################

  test "expense without a sku get lumped into non_sku_expenses" do
    statement = build_statement(-600,
      [
        detail(IpsStatementDetail::SECTION_EXPENSE, "Direct Fulfillment Freight & Handling Fees", "Direct Fulfillment Order Fees", -100, 1, -100,
          [
            line(:trevan_b, "expense", "Test expense", 1, -100),
          ]),
        detail(IpsStatementDetail::SECTION_EXPENSE, "DistributionFees", "Canadian Sales Gross", -200, 0, -200,
          [
            line(:pg_git_b, "expense", "Test expense", 0, -200),
          ]),
        detail(IpsStatementDetail::SECTION_EXPENSE, "Freight", "Direct Fulfillment Order Fees", -100, 1, -300,
          [
            line(nil, "expense", "Test expense", 1, -300),
          ]),
      ]
    )

    expected = [
      [ :trevan_b, "IPS-E", "Distribution: Fulfillment",       0, 0, 0, 1, -100, '2025-04-30', statement.id ],
      [ :trevan_b, "IPS-E", "Distribution: Marketing & Misc.", 0, 0, 0, 0, -150, '2025-04-30', statement.id ],
      [ :pg_git_b, "IPS-E", "Distribution: Fees",              0, 0, 0, 0, -200, '2025-04-30', statement.id ],
      [ :pg_git_b, "IPS-E", "Distribution: Marketing & Misc.", 0, 0, 0, 0, -150, '2025-04-30', statement.id ],
    ]
    assert_royalty_calculated(expected, statement)

    # assert_royalty_lines_saved(expected, statement)
  end



end
