require "test_helper"
require "pry"

class IpsRoyaltiesTest < ActiveSupport::TestCase

  # To test royalties, we have to be able to construct one or more statements, each with one or more
  # detais. Each detail will have one or more lines.
  #
  # We then constructure An IpsPayment with associated Payment Advice Lines. These get matched
  # against the detail lines to generate royalty items.


  def reconcile(statements, payment_lines_attrs)
    models = []
    statements.each do | s |
      statement = ips_statement!(s[:attrs] || {})
      statement.save!
      current = { statement:, details: [] }
      models.push(current)
      s[:details].each do |d|
        detail = ips_statement_detail!(d[:attrs].merge(ips_statement: statement))
        detail.due_this_month = d[:lines].sum { |line| line[:amount] || 0 }
        detail.save!

        cdetail = { detail:, lines: [] }
        current[:details] << cdetail
        d[:lines].each do |line_attrs|
          line = ips_detail_line!({ips_statement_detail: detail}.merge(line_attrs)).save!
          cdetail[:lines] << line
        end
      end
    end

    payment = ips_payment_advice!(total_amount: payment_lines_attrs.sum { |pl| pl[:paid_amount] })
    payment.save! || flunk(payment.errors.full_messages.to_sentence)
    payment_lines_attrs.each do |attrs|
      line = ips_payment_advice_line!(**attrs)
      line.ips_payment_advice = payment
      line.save! || flunk(line.errors.full_messages.to_sentence)
    end

    Royalties::Ips::ReconcilePayments.handle(payment)
    payment.reload

    { models:, payment: }
  end

  TODAY = Date.today.strftime('%Y-%m-%d')

  def assert_ri(ri, sku, item_type, description, paid_units, paid_amount, date, detail)
    assert_not_nil ri, "RoyaltyItem should be created"
    assert_equal skus(sku).id, ri.sku_id,                     "RoyaltyItem SKU should match"
    assert_equal item_type,    ri.item_type,                  "RoyaltyItem type should be IPS-R"
    assert_equal description,  ri.description,                "RoyaltyItem description should match"
    assert_equal paid_units,   ri.paid_units,                 "RoyaltyItem paid units should match"
    assert_equal paid_amount,  ri.paid_amount,                "RoyaltyItem paid amount should match"
    assert_equal 0,            ri.free_units,                 "RoyaltyItem free units should be zero"
    assert_equal 0,            ri.return_units,               "RoyaltyItem return units should be zero"
    assert_equal 0,            ri.return_amount,              "RoyaltyItem return amount should be zero"
    assert_equal TODAY,        ri.date.strftime('%Y-%m-%d'),  "RoyaltyItem date should be today"
    assert_equal detail.id,    ri.source_id,                  "RoyaltyItem source ID should match detail ID"
    assert_equal RoyaltyItem::APPLIES_TO_BOTH, ri.applies_to, "RoyaltyItem applies_to should be both"
    assert_equal IpsStatementDetail.name, ri.source_type,     "RoyaltyItem source type should be IpsStatement"
  end

  test "single match" do
    statements = [
      { attrs: {},          # statement
        details: [
          {
            attrs: { detail: "Domestic Gross Sales Excluding Canada", subsection: "Gross Sales", month_due: Date.new(2025, 4, 1) },
            lines: [
              { sku: :trevan_b, content_type: "all_revenues", description: "Test Royalty", quantity: 2, amount: 500 },
            ],
          },
        ],
      }
    ]

    payment_lines = [
      { paid_amount: 500 },
    ]

    reconcile(statements, payment_lines) => { models:, payment: }

    detail = models[0][:details][0][:detail]
    detail.reload

    assert detail.reconciled?, "Detail should be reconciled"

    payment_line = payment.ips_payment_advice_lines.first
    assert_equal payment_line.status, IpsPaymentAdviceLine::STATUS_RECONCILED, "Payment line should be reconciled"
    assert_equal detail, payment_line.ips_statement_details[0], "Payment line should be linked to detail"

    Royalties::Ips::Import.build_royalties_from_details(payment)

    ri = RoyaltyItem.first

    assert_ri(ri, :trevan_b, "IPS-R", "Distribution: Domestic Sales (Mar '25)", 2, 500, '2025-04-01', detail)
  end

  test "single match where there are two pending details" do
    statements = [
      { details: [
        {
          attrs: { detail: "Domestic Gross Sales Excluding Canada", subsection: "Gross Sales", month_due: Date.new(2025, 4, 1) },
          lines: [
            { sku: :trevan_b, content_type: "all_revenues", description: "Test Royalty", quantity: 2, amount: 400 },
          ],
        },
        {
          attrs: { detail: "Domestic Gross Sales Excluding Canada", subsection: "Gross Sales", month_due: Date.new(2025, 4, 1) },
          lines: [
            {sku: :trevan_b, content_type: "all_revenues", description: "Test Royalty", quantity: 2, amount: 500 },
          ],
        },
      ]
      }
    ]

    payment_lines = [
      { paid_amount: 500 },
    ]

    reconcile(statements, payment_lines) => { models:, payment: }

    detail = models[0][:details][0][:detail]
    detail.reload
    assert_not detail.reconciled?, "Detail should not be reconciled"

    detail = models[0][:details][1][:detail]
    detail.reload
    assert detail.reconciled?, "Detail should be reconciled"

    payment_line = payment.ips_payment_advice_lines.first
    assert_equal payment_line.status, IpsPaymentAdviceLine::STATUS_RECONCILED, "Payment line should be reconciled"
    assert_equal detail, payment_line.ips_statement_details[0], "Payment line should be linked to detail"

    Royalties::Ips::Import.build_royalties_from_details(payment)

    ri = RoyaltyItem.first

    assert_ri(ri, :trevan_b, "IPS-R", "Distribution: Domestic Sales (Mar '25)", 2, 500, '2025-04-01', detail)
  end
  # ######################################################################
  #
  # test "statement with different total to sum(rls) fails" do
  #   statement = build_statement(300,
  #     [ detail(IpsStatementDetail::SECTION_REVENUE, "Gross Sales", "Domestic Gross Sales Excluding Canada", 300, 1, 300,
  #         [ line(:trevan_b, "royalty", "Test Royalty", 2, 500), ])
  #     ]
  #   )
  #   error = assert_raises(RuntimeError) do
  #     Royalties::Ips::ImportHandler.import(statement)
  #   end
  #   assert_match(%r[Net client earnings mismatch—\nstatement: \$300.00,\ncalculated: \$500.00]m, error.message)
  # end
  #
  # ######################################################################
  #
  test "statement with one detail and two lines with the same description for same sku creates one royalty line" do
    statements = [
      {
        details: [
          {
            attrs: { detail: "Domestic Gross Sales Excluding Canada", subsection: "Gross Sales", month_due: Date.new(2025, 4, 1) },
            lines: [
              { sku: :trevan_b, content_type: "all_revenues", description: "Test Royalty", quantity: 2, amount: 200 },
              { sku: :trevan_b, content_type: "all_revenues", description: "Test Royalty", quantity: 3, amount: 300 },
            ],
          }
        ],
      },
    ]
    payment_lines = [
      { paid_amount: 500 },
    ]

    reconcile(statements, payment_lines) => { models:, payment: }

    detail = models[0][:details][0][:detail]
    detail.reload
    assert detail.reconciled?, "Detail 1 should be reconciled"

    payment_line = payment.ips_payment_advice_lines.first
    assert_equal payment_line.status, IpsPaymentAdviceLine::STATUS_RECONCILED, "Payment line should be reconciled"
    assert_equal detail, payment_line.ips_statement_details[0], "Payment line should be linked to detail"

    Royalties::Ips::Import.build_royalties_from_details(payment)

    assert_equal 1, RoyaltyItem.count
    ri = RoyaltyItem.first
    # binding.irb
    assert_ri(ri, :trevan_b, "IPS-R", "Distribution: Domestic Sales (Mar '25)", 5, 500, '2025-04-01', detail)
  end

  # ######################################################################

  test "statement with two details, one line each for same sku creates correct royalty line" do
    statements = [
      {
        details: [
          {
            attrs: { detail: "Domestic Gross Sales Excluding Canada", subsection: "Gross Sales", month_due: Date.new(2025, 4, 1) },
            lines: [
              { sku: :trevan_b, content_type: "all_revenues", description: "Test Royalty", quantity: 2, amount: 200 },
            ],
          },
          {
            attrs: { detail: "Domestic Gross Sales Excluding Canada", subsection: "Gross Sales", month_due: Date.new(2025, 4, 1) },
            lines: [
              { sku: :trevan_b, content_type: "all_revenues", description: "Test Royalty", quantity: 3, amount: 300 },
            ],
          },
        ],
      }
    ]

    payment_lines = [
      { paid_amount: 300 },
      { paid_amount: 200 },
    ]

    reconcile(statements, payment_lines) => { models:, payment: }

    detail1 = models[0][:details][0][:detail]
    detail1.reload
    assert detail1.reconciled?, "Detail 1 should be reconciled"

    detail2 = models[0][:details][1][:detail]
    detail2.reload
    assert detail2.reconciled?, "Detail 1 should be reconciled"

    payment_line = payment.ips_payment_advice_lines.first
    assert_equal payment_line.status, IpsPaymentAdviceLine::STATUS_RECONCILED, "Payment line should be reconciled"
    assert_equal detail2, payment_line.ips_statement_details[0], "Payment line should be linked to detail"

    payment_line = payment.ips_payment_advice_lines.last
    assert_equal payment_line.status, IpsPaymentAdviceLine::STATUS_RECONCILED, "Payment line should be reconciled"
    assert_equal detail1, payment_line.ips_statement_details[0], "Payment line should be linked to detail"

    Royalties::Ips::Import.build_royalties_from_details(payment)

    ri = RoyaltyItem.first

    assert_ri(ri, :trevan_b, "IPS-R", "Distribution: Domestic Sales (Mar '25)", 5, 500, '2025-04-01', detail2)
  end

  #  # ######################################################################

  test "two statements (different dates) with one detail for same sku creates two royalty lines" do
    statements = [
      { attrs: { month_ending: Date.new(2025, 3, 31) },
        details: [
          {
            attrs: { detail: "Domestic Gross Sales Excluding Canada", subsection: "Gross Sales", month_due: Date.new(2025, 5, 1) },
            lines: [
              { sku: :trevan_b, content_type: "all_revenues", description: "Test Royalty", quantity: 3, amount: 300 },
            ],
          },
        ],
      },
      { attrs: { month_ending: Date.new(2025, 4, 30) },
        details: [
          {
            attrs: { detail: "Domestic Gross Sales Excluding Canada", subsection: "Gross Sales", month_due: Date.new(2025, 4, 1) },
            lines: [
              { sku: :trevan_b, content_type: "all_revenues", description: "Test Royalty", quantity: 2, amount: 200 },
            ],
          },
        ],
      }
    ]

    payment_lines = [
      { paid_amount: 300 },
      { paid_amount: 200 },
    ]

    reconcile(statements, payment_lines) => { models:, payment: }

    detail1 = models[0][:details][0][:detail]
    detail1.reload
    assert detail1.reconciled?, "Detail 1 should be reconciled"

    detail2 = models[1][:details][0][:detail]
    detail2.reload
    assert detail2.reconciled?, "Detail 1 should be reconciled"

    payment_line = payment.ips_payment_advice_lines.first
    assert_equal payment_line.status, IpsPaymentAdviceLine::STATUS_RECONCILED, "Payment line should be reconciled"
    assert_equal detail1, payment_line.ips_statement_details[0], "Payment line should be linked to detail"

    payment_line = payment.ips_payment_advice_lines.last
    assert_equal payment_line.status, IpsPaymentAdviceLine::STATUS_RECONCILED, "Payment line should be reconciled"
    assert_equal detail2, payment_line.ips_statement_details[0], "Payment line should be linked to detail"

    Royalties::Ips::Import.build_royalties_from_details(payment)

    ri = RoyaltyItem.first
    assert_ri(ri, :trevan_b, "IPS-R", "Distribution: Domestic Sales (Mar '25)", 3, 300, '2025-04-01', detail1)
    ri = RoyaltyItem.last
    assert_ri(ri, :trevan_b, "IPS-R", "Distribution: Domestic Sales (Apr '25)", 2, 200, '2025-04-01', detail2)
  end



  # ######################################################################

  # test "statement with two details, one line each for different sku creates correct royalty line" do
  #   statement = build_statement(500,
  #     [
  #       detail(IpsStatementDetail::SECTION_REVENUE, "Gross Sales", "Domestic Gross Sales Excluding Canada", 200, 1, 200,
  #         [
  #           line(:trevan_b, "royalty", "Test Royalty", 2, 200),
  #         ]),
  #       detail(IpsStatementDetail::SECTION_REVENUE, "Gross Sales", "Ebook Sales Gross", 300, 3, 300,
  #         [
  #           line(:pg_git_b, "royalty", "Test Royalty", 3, 300),
  #         ])
  #     ]
  #   )
  #
  #   expected = [
  #     [ :trevan_b, "IPS-R", "Distribution: Domestic Sales", 0, 2, 200, 0, 0, '2025-04-30', statement.id ],
  #     [ :pg_git_b, "IPS-R", "Distribution: Ebook Sales",    0, 3, 300, 0, 0, '2025-04-30', statement.id ],
  #   ]
  #   assert_royalty_calculated(expected, statement)
  #   assert_royalty_lines_saved(expected, statement)
  # end
  #
  # ######################################################################
  #
  # test "statement with two details, one sale line and one return" do
  #   statement = build_statement(100,
  #     [
  #       detail(IpsStatementDetail::SECTION_REVENUE, "Gross Sales", "Domestic Gross Sales Excluding Canada", 100, 1, 100,
  #         [
  #           line(:trevan_b, "royalty", "Test Royalty", 2, 200),
  #         ]),
  #       detail(IpsStatementDetail::SECTION_REVENUE, "Returns", "Ebook Returns", 100, 1, 100,
  #         [
  #           line(:pg_git_b, "royalty", "Test Royalty", -1, -100),
  #         ])
  #     ]
  #   )
  #
  #   expected = [
  #     [ :trevan_b, "IPS-R", "Distribution: Domestic Sales", 0, 2, 200, 0, 0, '2025-04-30', statement.id ],
  #     [ :pg_git_b, "IPS-R", "Distribution: Ebook Returns",  0, 0, 0, -1, -100, '2025-04-30', statement.id ],
  #   ]
  #   assert_royalty_calculated(expected, statement)
  #   assert_royalty_lines_saved(expected, statement)
  # end
  #
  #
  # ######################################################################
  #
  # test "expense categorization" do
  #   statement = build_statement(-1500,
  #     [
  #       detail(IpsStatementDetail::SECTION_EXPENSE, "Direct Fulfillment Freight & Handling Fees", "Direct Fulfillment Order Fees", -100, 1, -100,
  #         [
  #           line(:trevan_b, "expense", "Test expense", 1, -100),
  #         ]),
  #       detail(IpsStatementDetail::SECTION_EXPENSE, "DistributionFees", "Canadian Sales Gross", -200, 0, -200,
  #         [
  #           line(:pg_git_b, "expense", "Test expense", 0, -200),
  #         ]),
  #       detail(IpsStatementDetail::SECTION_EXPENSE, "Freight", "Direct Fulfillment Order Fees", -100, 1, -300,
  #         [
  #           line(:trevan_p, "expense", "Test expense", 1, -300),
  #         ]),
  #       detail(IpsStatementDetail::SECTION_EXPENSE, "Lightning Source Services", "LSI Charges Print to Order Printing", -400, 0, -400,
  #         [
  #           line(:pg_git_p, "expense", "Test expense", 0, -400),
  #         ]),
  #       detail(IpsStatementDetail::SECTION_EXPENSE, "Other fees", "Co-Op", -500, 1, -500,
  #         [
  #           line(:trevan_s, "expense", "Test expense", 0, -500),
  #         ]),
  #     ]
  #   )
  #
  #   expected = [
  #     [ :trevan_b, "IPS-E", "Distribution: Fulfillment",       0, 0, 0, 1, -100, '2025-04-30', statement.id ],
  #     [ :pg_git_b, "IPS-E", "Distribution: Fees",              0, 0, 0, 0, -200, '2025-04-30', statement.id ],
  #     [ :trevan_p, "IPS-E", "Distribution: Fulfillment",       0, 0, 0, 1, -300, '2025-04-30', statement.id ],
  #     [ :pg_git_p, "IPS-E", "Printing costs",                  0, 0, 0, 0, -400, '2025-04-30', statement.id ],
  #     [ :trevan_s, "IPS-E", "Distribution: Marketing & Misc.", 0, 0, 0, 0, -500, '2025-04-30', statement.id ],
  #   ]
  #   assert_royalty_calculated(expected, statement)
  #   assert_royalty_lines_saved(expected, statement)
  # end
  #
  # ######################################################################
  #
  # test "expense without a sku get lumped into non_sku_expenses" do
  #   statement = build_statement(-600,
  #     [
  #       detail(IpsStatementDetail::SECTION_EXPENSE, "Direct Fulfillment Freight & Handling Fees", "Direct Fulfillment Order Fees", -100, 1, -100,
  #         [
  #           line(:trevan_b, "expense", "Test expense", 1, -100),
  #         ]),
  #       detail(IpsStatementDetail::SECTION_EXPENSE, "DistributionFees", "Canadian Sales Gross", -200, 0, -200,
  #         [
  #           line(:pg_git_b, "expense", "Test expense", 0, -200),
  #         ]),
  #       detail(IpsStatementDetail::SECTION_EXPENSE, "Freight", "Direct Fulfillment Order Fees", -100, 1, -300,
  #         [
  #           line(nil, "expense", "Test expense", 1, -300),
  #         ]),
  #     ]
  #   )
  #
  #   expected = [
  #     [ :trevan_b, "IPS-E", "Distribution: Fulfillment",       0, 0, 0, 1, -100, '2025-04-30', statement.id ],
  #     [ :trevan_b, "IPS-E", "Distribution: Marketing & Misc.", 0, 0, 0, 0, -150, '2025-04-30', statement.id ],
  #     [ :pg_git_b, "IPS-E", "Distribution: Fees",              0, 0, 0, 0, -200, '2025-04-30', statement.id ],
  #     [ :pg_git_b, "IPS-E", "Distribution: Marketing & Misc.", 0, 0, 0, 0, -150, '2025-04-30', statement.id ],
  #   ]
  #   assert_royalty_calculated(expected, statement)
  #
  #   # assert_royalty_lines_saved(expected, statement)
  # end
  #
  #

end

