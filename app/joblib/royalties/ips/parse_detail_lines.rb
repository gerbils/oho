require 'pry'
module Royalties::Ips::ParseDetailLines
  extend self
  extend Royalties::Shared

  Detail = Struct.new("DetailLine", :ean, :description, :title, :quantity, :amount, :content_type)

  module Type1
    # CanadianFreightPctofSales.xlsx
    # DomesticFreightPctofSales.xlsx
    # InternationalFreightPctofSales.xlsx
    HEADINGS = [
      "Year", "Period", "Pub Num", "Publisher Name", "Pub Alpha", "Brand Category", "Imprint", "EAN", "Title", "Domestic Freight",
      "Gift Freight", "International Freight", "Canadian Freight", "Total Freight"
    ]
    def self.extract(row)
      description = "Freight"
      ean      = row[7].cell_value
      title    = row[8].cell_value
      amount   = BigDecimal(row[-1].cell_value)
      quantity = 0
      Detail.new(ean:, description:, title:, quantity:, amount:, content_type: "freight")
    end
  end

  module Type2
    # CanadianSalesGross.xlsx
    # DomesticGrossReturns.xlsx
    # DomesticGrossSales.xlsx
    # GlobalConnectLSIFees-UK.xlsx
    # InternationalDirectGross.xlsx
    # InternationalDirectReturns.xlsx
    # UKPODDistributionFee.xlsx
    # UKWarehouseReturns.xlsx
    # UKWarehouseSales.xlsx
    HEADINGS = [
      "EAN", "Title", "Format", "List Amount", "Pub Alpha", "Brand Category", "Imprint", "Date", "Customer PO / Claim #",
      "Invoice / Credit Memo #", "Customer Discount", "Type", "Fee Factor Pct", "Sum of Qty", "Sum of Value",
      "Sum of Total Fee", "HQ Account #", "Headquarter", "Shipping Location", "SL City", "SL State"
    ]
    def self.extract(row)

      description = "Distribution fee"
      ean = row[0].cell_value
      title = row[1].cell_value
      quantity = row[13].value
      amount = BigDecimal(row[15].cell_value)
      Detail.new(ean:, description:, title:, quantity:, amount:, content_type: "expense1")
    end
  end

  module Type3
    # DFRegularFees.xlsx
    # DirectFulfillmentOrderFees.xlsx
    # DirectFulfillmentUnitsFees.xlsx

    HEADINGS = [
      "Invoice Date", "Invoice Number", "Bill to Number", "Customer PO", "DF Name", "DF Address 1", "DF Address 2",
      "DF Address 3", "DF City", "DF State", "DF Zip", "PUB NUM", "Imprint", "Pub Alpha", "QTY", "Total List",
      "IPS INVC", "# of ISBNs", "Carton Count", "Carton Charge", "Loose Units", "Loose Charge",
      "SKID CNT", "SKID Charge", "Title Count", "Title Charge", "Total Amount"
    ]
    def self.extract(row)
      description = "Direct Fulfillment"
      ean = nil
      title = nil
      quantity = row[14].value
      amount = BigDecimal(row[-1].cell_value)
      Detail.new(ean:, description:, title:, quantity:, amount:, content_type: "df_expense")
    end
  end

  module Type4
    # LSIChargesDropShipPrintUK.xlsx
    # LSIChargesPrintToOrderPrinting.xlsx
    HEADINGS = [
      "Invoice Date", "Invoice Type", "Invoice Number", "Currency Code", "Invoice Due Date",
      "Bill to Customer Name", "ISBN", "Description", "Quantity Shipped", "Functional Unit Amount",
      "Functional Extended Amount", "Tax Rate", "Tax Amount", "Total"
    ]

    def self.extract(row)
      description = case row[1].value
                    when "Inv-PTO" then "Printing"
                    when "Inv-DS"  then "Drop Ship"
                    when "CM"      then "Printing"
                    else
                      raise "Type 4: Unknown invoice type: #{row[1].value}"
                    end

      ean = row[6].cell_value
      if ean
        title = row[7].cell_value
      end
      quantity = row[8].value
      amount = BigDecimal(row[-1].cell_value)
      Detail.new(ean:, description:, title:, quantity:, amount:, content_type: "lsi_expense")
    end
  end

  module Type5
    # MiscExpense.xlsx
    HEADINGS = [
      "Year", "Period", "Misc Item Id", "Pub #", "Pub Name", "Pub Alpha", "Brand Category",
      "Imprint", "EAN", "Title", "Statement Section", "Statement Sub-Section", "Transaction Type",
      "Description of Statement", "Credit or Charge", "Unit Quantity", "Unit Amount", "Misc Amount"
    ]

    def self.extract(row)
      description = row[13].value
      ean = row[8]&.cell_value
      title = row[9]&.cell_value
      quantity = row[-3].value
      amount = BigDecimal(row[-1].cell_value)
      Detail.new(ean:, description:, title:, quantity:, amount:, content_type: "misc_expense")
    end
  end

  module AllRevenues

    HEADINGS = [
      "EAN", "Title", "Format", "List Amount", "Pub Alpha", "Brand Category",
      "Imprint", "Date", "Customer PO / Claim #", "Invoice / Credit Memo #",
      "Customer Discount", "Type", "Qty", "Value", "HQ Account #",
      "Headquarter", "Shipping Location", "SL City", "SL State",
    ]

    def self.extract(row)
      description = "Revenue"
      ean = row[0].cell_value
      title = row[1].cell_value
      quantity = row[12].value
      amount = BigDecimal(row[13].cell_value)
      Detail.new(ean:, description:, title:, quantity:, amount:, content_type: "all_revenues")
    end
  end

  ALL_TYPES = [ Type1, Type2, Type3, Type4, Type5, AllRevenues ]

  def find_handler_module(headers)
    ALL_TYPES.find do |type|
      type::HEADINGS.zip(headers).all? {|a,b| a == b }
    end || raise("No matching handler found for headers:\n#{headers}")
  end

  def to_h(handler, row)
    headers = handler::HEADINGS
    fail "Mismatched columns: expected #{headers.size} columns, got #{row.size}" if headers.size != row.size
    Hash[headers.zip(row.map(&:cell_value))]
  end

  def parse(statement, content, file_type)
    sheet = open_spreadsheet(content, file_type)
    sheet.default_sheet = sheet.sheets.first
    next_row = sheet.first_row

    headers = sheet.row(next_row)
    handler = find_handler_module(headers)
    lines = []

    skip_header = true

    sheet.each_row_streaming do |row|
      if skip_header
        skip_header = false
        next
      end

      result = handler.extract(row)
      hash = to_h(handler, row)

      lines << IpsDetailLine.new(
        ean: result.ean,
        sku_id: map_ean_to_sku(result),
        content_type: result.content_type,
        title: result.title,
        description: result.description,
        quantity: result.quantity,
        amount: result.amount,
        json: hash.to_json
      )
    end
    lines
  end

  ######################################################################

  def map_ean_to_sku(row)
    case  Product.product_and_sku_for_isbn(row.ean)

    in [ nil, nil ]                  # non-specific expense
      return nil

    in [ Product => product, Sku => sku ]
      if row.title.blank? || titles_similar(product.title, row.title)
        return sku.id
      end
      raise("Title mismatch #{isbn}: #{product.title.inspect} " +
            "doesn't start with #{row.title.inspect} " +
            "(#{normalize(product.title)} vs. #{normalize(row.title)} )")
    else
      raise"ISBN #{isbn} not found"
    end
    raise "never get here"
  end

  def normalize(title)
    title
      .downcase
      .tr("^a-z0-9", "")
      .sub(/(2nd|3rd|4th|5th|6th|7th|8th|9th|second|third|fourth|fifth|sixth|seventh|eighth|ninth)ed(ition)?/, "")
      .strip
  end

  def titles_similar(pip, ips)
    pip = normalize(pip)
    ips = normalize(ips)
    len = [ pip.length, ips.length ].min
    fail "zero length title" if len == 0
    pip[0...len] == ips[0...len]
  end


end

