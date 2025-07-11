require 'test_helper'
require 'bigdecimal'

class IpsUploadPaymentAdviceTest < ActiveSupport::TestCase

  def sheet(name)
    File.read(File.join("test/fixtures/files/royalties", "#{name}.xlsx"))
  end

  def parse(sheet)
    s = IpsPaymentAdvice.new
    Royalties::Ips::ParsePaymentAdvice.parse(s, sheet(sheet), "xlsx")
  end

  def assert_equal?(expected, actual, message = nil)
    if expected.nil?
      assert_nil actual, message || "Both values are nil"
    else
      assert_equal expected, actual, message || "Expected #{expected.inspect}, got #{actual.inspect}"
    end
  end


  # def assert_parse(sheet_name, expected_lines)
  #   lines = parse(sheet_name)
  #   assert_equal expected_lines.size, lines.size, "Expected #{expected_lines.size} lines, got #{lines.size}"
  #   expected_lines.zip(lines).each do |expected, got|
  #     assert_equal? expected[:ean], got.ean, "EAN mismatch for #{expected[:title]}"
  #     assert_equal expected[:content_type], got.content_type, "Content type mismatch for #{expected[:title]}"
  #     assert_equal? expected[:title], got.title, "Title mismatch for #{expected[:title]}"
  #     assert_equal expected[:description], got.description, "Description mismatch for #{expected[:title]}"
  #     assert_equal expected[:quantity], got.quantity, "Quantity mismatch for #{expected[:title]}"
  #     assert_equal BigDecimal(expected[:amount]), got.amount, "Amount mismatch for #{expected[:title]}"
  #   end
  # end

  test "overall details for a correct sheet" do
    a = parse("CON-2025-07")

    assert_equal "EFT3", a.pay_cycle
    assert_equal "1460", a.pay_cycle_seq_number
    assert_equal "182039", a.payment_reference
    assert_equal Date.new(2025,7,8), a.payment_date
    assert_equal BigDecimal("5564.87"), a.total_amount
  end

  DETAILS = [
    [ "S330 CoOp Charges",              "04/30/2025", "00709489", "-115.73",  "0.00", "-115.73",     ],
    [ "S330 CoOp Charges",              "05/31/2025", "00719219", "-1669.87", "0.00", "-1669.87",    ],
    [ "S330 CoOp Charges",              "06/30/2025", "00728902", "-992.77",  "0.00", "-992.77",     ],
    [ "S330 Direct Fulfillment Freigh", "06/30/2025", "00728903", "-943.03",  "0.00", "-943.03",     ],
    [ "S330 Direct Fulfillment Freigh", "05/31/2025", "00719220", "-376.41",  "0.00", "-376.41",     ],
    [ "S330 Direct Fulfillment Freigh", "04/30/2025", "00709490", "-258.16",  "0.00", "-258.16",     ],
    [ "S330 Direct Fulfillment Freigh", "03/31/2025", "00699952", "-19.18",   "0.00", "-19.18",      ],
    [ "S330 Fee - DF carton",           "05/31/2025", "00719243", "-21.00",   "0.00", "-21.00",      ],
    [ "S330 Fee - DF carton",           "06/30/2025", "00728923", "-7.00",    "0.00", "-7.00",       ],
    [ "S330 Fee - DF order",            "06/30/2025", "00728924", "-51.25",   "0.00", "-51.25",      ],
    [ "S330 Fee - DF order",            "05/31/2025", "00719244", "-3.75",    "0.00", "-3.75",       ],
    [ "S330 Fee - DF order",            "04/30/2025", "00709513", "-23.75",   "0.00", "-23.75",      ],
    [ "S330 Fee - DF order",            "03/31/2025", "00699972", "-1.25",    "0.00", "-1.25",       ],
    [ "S330 Fee - DF unit",             "03/31/2025", "00699973", "-0.60",    "0.00", "-0.60",       ],
    [ "S330 Fee - DF unit",             "04/30/2025", "00709514", "-30.60",   "0.00", "-30.60",      ],
    [ "S330 Fee - DF unit",             "05/31/2025", "00719245", "-1.80",    "0.00", "-1.80",       ],
    [ "S330 Fee - DF unit",             "06/30/2025", "00728925", "-56.40",   "0.00", "-56.40",      ],
    [ "S330 Fee Gross Digital",         "03/31/2025", "00699956", "-711.78",  "0.00", "-711.78",     ],
    [ "S330 Fee INTL Gross Returns",    "03/31/2025", "00699958", "3.59",     "0.00", "3.59",        ],
    [ "S330 Fee INTL Gross Returns",    "04/30/2025", "00709496", "5.24",     "0.00", "5.24",        ],
    [ "S330 Fee INTL Gross Returns",    "06/30/2025", "00728908", "8.09",     "0.00", "8.09",        ],
    [ "S330 Fee INTL Gross Returns",    "05/31/2025", "00719226", "7.19",     "0.00", "7.19",        ],
    [ "S330 Fee INTL Gross Sales",      "03/31/2025", "00699965", "-187.80",  "0.00", "-187.80",     ],
    [ "S330 Fee INTL Gross Sales",      "02/28/2025", "00690641", "-24.87",   "0.00", "-24.87",      ],
    [ "S330 Fee INTL Net Sales",        "03/31/2025", "00699955", "-230.77",  "0.00", "-230.77",     ],
    [ "S330 Fee INTL on Returns",       "05/31/2025", "00719227", "13.45",    "0.00", "13.45",       ],
    [ "S330 Fee INTL on Returns",       "06/30/2025", "00728909", "16.94",    "0.00", "16.94",       ],
    [ "S330 Fee INTL on Returns",       "03/31/2025", "00699959", "4.93",     "0.00", "4.93",        ],
    [ "S330 Fee INTL on Returns",       "04/30/2025", "00709497", "15.18",    "0.00", "15.18",       ],
    [ "S330 Fee US Gross Returns",      "03/31/2025", "00699968", "223.83",   "0.00", "223.83",      ],
    [ "S330 Fee US Gross Returns",      "02/28/2025", "00690644", "54.68",    "0.00", "54.68",       ],
    [ "S330 Fee US Gross Returns",      "05/31/2025", "00719237", "181.90",   "0.00", "181.90",      ],
    [ "S330 Fee US Gross Returns",      "06/30/2025", "00728919", "35.63",    "0.00", "35.63",       ],
    [ "S330 Fee US Gross Returns",      "04/30/2025", "00709507", "453.43",   "0.00", "453.43",      ],
    [ "S330 Fee US Gross Sales",        "02/28/2025", "00690646", "-481.66",  "0.00", "-481.66",     ],
    [ "S330 Fee US Gross Sales",        "03/31/2025", "00699970", "-2898.24", "0.00", "-2898.24",    ],
    [ "S330 Gross Digital Returns",     "03/31/2025", "00699953", "-130.59",  "0.00", "-130.59",     ],
    [ "S330 Gross Digital Sales",       "03/31/2025", "00699954", "6062.11",  "0.00", "6062.11",     ],
    [ "S330 INTL Gross Returns",        "03/31/2025", "00699957", "-34.08",   "0.00", "-34.08",      ],
    [ "S330 INTL Gross Returns",        "04/30/2025", "00709495", "-81.70",   "0.00", "-81.70",      ],
    [ "S330 INTL Gross Returns",        "05/31/2025", "00719225", "-82.56",   "0.00", "-82.56",      ],
    [ "S330 INTL Gross Returns",        "06/30/2025", "00728907", "-100.15",  "0.00", "-100.15",     ],
    [ "S330 INTL Gross Sales",          "03/31/2025", "00699961", "751.19",   "0.00", "751.19",      ],
    [ "S330 INTL Gross Sales",          "02/28/2025", "00690640", "99.48",    "0.00", "99.48",       ],
    [ "S330 LSI Invoices",              "02/28/2025", "00690647", "-650.68",  "0.00", "-650.68",     ],
    [ "S330 LSI Invoices",              "03/31/2025", "00699971", "-6108.34", "0.00", "-6108.34",    ],
    [ "S330 Misc Charges",              "04/30/2025", "00709502", "-445.58",  "0.00", "-445.58",     ],
    [ "S330 Misc Charges",              "03/31/2025", "00699964", "-131.63",  "0.00", "-131.63",     ],
    [ "S330 Misc Charges",              "05/31/2025", "00719232", "-965.52",  "0.00", "-965.52",     ],
    [ "S330 Misc Charges",              "06/30/2025", "00728914", "-619.83",  "0.00", "-619.83",     ],
    [ "S330 OUTFRT CDN Contract %",     "05/31/2025", "00719234", "-10.20",   "0.00", "-10.20",      ],
    [ "S330 OUTFRT CDN Contract %",     "04/30/2025", "00709504", "-3.31",    "0.00", "-3.31",       ],
    [ "S330 OUTFRT DOM Contract %",     "04/30/2025", "00709505", "-5.04",    "0.00", "-5.04",       ],
    [ "S330 OUTFRT DOM Contract %",     "03/31/2025", "00699966", "-8.68",    "0.00", "-8.68",       ],
    [ "S330 OUTFRT DOM Contract %",     "02/28/2025", "00690642", "-5.33",    "0.00", "-5.33",       ],
    [ "S330 OUTFRT DOM Contract %",     "05/31/2025", "00719235", "-11.44",   "0.00", "-11.44",      ],
    [ "S330 OUTFRT DOM Contract %",     "06/30/2025", "00728917", "-3.23",    "0.00", "-3.23",       ],
    [ "S330 OUTFRT INTL Contract %",    "06/30/2025", "00728910", "-48.32",   "0.00", "-48.32",      ],
    [ "S330 OUTFRT INTL Contract %",    "05/31/2025", "00719228", "-5.54",    "0.00", "-5.54",       ],
    [ "S330 OUTFRT INTL Contract %",    "02/28/2025", "00690639", "-4.48",    "0.00", "-4.48",       ],
    [ "S330 OUTFRT INTL Contract %",    "03/31/2025", "00699960", "-5.83",    "0.00", "-5.83",       ],
    [ "S330 OUTFRT INTL Contract %",    "04/30/2025", "00709498", "-5.07",    "0.00", "-5.07",       ],
    [ "S330 US Gross Returns",          "04/30/2025", "00709506", "-3022.86", "0.00", "-3022.86",    ],
    [ "S330 US Gross Returns",          "03/31/2025", "00699967", "-1492.22", "0.00", "-1492.22",    ],
    [ "S330 US Gross Returns",          "02/28/2025", "00690643", "-364.56",  "0.00", "-364.56",     ],
    [ "S330 US Gross Returns",          "05/31/2025", "00719236", "-1212.70", "0.00", "-1212.70",    ],
    [ "S330 US Gross Returns",          "06/30/2025", "00728918", "-237.56",  "0.00", "-237.56",     ],
    [ "S330 US Gross Sales",            "02/28/2025", "00690645", "3211.10",  "0.00", "3211.10",     ],
    [ "S330 US Gross Sales",            "03/31/2025", "00699969", "19321.61", "0.00", "19321.61"  ],
  ]

  test "Detail Lines" do
    advice = parse("CON-2025-07")
    DETAILS.zip(advice.ips_payment_advice_lines).each do |expected, actual|
      m = "#{expected[0]} (#{expected[1]})"
      assert_equal(expected[0], actual.invoice_number, m)
      assert_equal(Date.strptime(expected[1], "%m/%d/%Y"), actual.invoice_date, m)
      assert_equal(expected[2], actual.voucher_id, m)
      assert_equal(BigDecimal(expected[3]), actual.gross_amount, m)
      assert_equal(BigDecimal(expected[4]), actual.discount_taken, m)
      assert_equal(BigDecimal(expected[5]), actual.paid_amount, m)
    end
  end
  # Uncomment the following tests when the corresponding methods are implemented

  # test "detects type 0 files" do
  #   assert_parse("ips_type_0_ok", [
  #     { ean: "9798888651049",
  #       content_type: "freight",
  #       title: "Agile Web Development with Rails 7.2",
  #       description: "Freight",
  #       quantity: 0,
  #       amount: "-3.3128",
  #     },
  #   ])
  # end
  # test "detects type 1 files" do
  #   assert_parse("ips_type_1_ok", [
  #     { ean: "9798888651049",
  #       content_type: "freight",
  #       title: "Agile Web Development with Rails 7.2",
  #       description: "Freight",
  #       quantity: 0,
  #       amount: "-3.3128",
  #     },
  #   ])
  # end
  #
  # test "detects type 2 files" do
  #   assert_parse("ips_type_2_ok", [
  #     { ean: "9798888651049",
  #       content_type: "expense1",
  #       title: "Agile Web Development with Rails 7.2",
  #       description: "Distribution fee",
  #       quantity: 1,
  #       amount: "-9.2757",
  #     },
  #   ])
  # end
  #
  # test "detects type 3 files" do
  #   assert_parse("ips_type_3_ok", [
  #     { ean: nil,
  #       content_type: "df_expense",
  #       title: nil,
  #       description: "Direct Fulfillment",
  #       quantity: 1,
  #       amount: "-3.84",
  #     },
  #   ])
  # end
  #
  # test "detects type 4 files" do
  #   assert_parse("ips_type_4_ok", [
  #     { ean: "9781934356456",
  #       content_type: "lsi_expense",
  #       title: "Language Implementation Patterns : Create Your Own Domain-Specific and General Programming Languages",
  #       description: "Drop Ship",
  #       quantity: 1,
  #       amount: "-7.64",
  #     },
  #   ])
  # end
  #
  # test "detects type 5 files" do
  #   assert_parse("ips_type_5_ok", [
  #     { ean: nil,
  #       content_type: "misc_expense",
  #       title: nil,
  #       description: "Amazon Freight- March",
  #       quantity: 0,
  #       amount: "-279.49",
  #     },
  #   ])
  # end
  #
  # test "detects revenue files" do
  #   assert_parse("ips_revenue_ok", [
  #     { ean: "9798888651049",
  #       content_type: "all_revenues",
  #       title: "Agile Web Development with Rails 7.2",
  #       description: "Revenue",
  #       quantity: 1,
  #       amount: "44.17",
  #     },
  #   ])
  # end

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
