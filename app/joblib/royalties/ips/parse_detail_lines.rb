module Royalties::Ips::ParseDetailLines
  extend self
  extend Royalties::Shared

  Detail = Struct.new("Detail", :ean, :description, :title, :quantity, :amount)
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
      ean = row[7]
      title = row[8]
      quantity = 0
      amount = BigDecimal(row[-1].to_s)
      Detail.new(ean:, description:, title:, quantity:, amount:)
    end
  end

  module Type2
    # CanadianSalesGross.xlsx
    # DigitalDistributionFees-LSI.xlsx
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
      "Invoice / Credit Memo #", "Customer Discount", "description", "Fee Factor Pct", "Sum of quantity", "Sum of Value",
      "Sum of Total Fee", "HQ Account #", "Headquarter", "Shipping Location", "SL City", "SL State"
    ]
    def self.extract(row)
      description = "Distribution fee"
      ean = row[0]
      title = row[1]
      quantity = row[13]
      amount = BigDecimal(row[15].to_s)
      Detail.new(ean:, description:, title:, quantity:, amount:)
    end
  end

  module Type3
    # DFRegularFees.xlsx
    # DirectFulfillmentOrderFees.xlsx
    HEADINGS = [
      "Invoice Date", "Invoice Number", "Bill to Number", "Customer PO", "DF Name", "DF Address 1", "DF Address 2",
      "DF Address 3", "DF City", "DF State", "DF Zip", "PUB NUM", "Imprint", "Pub Alpha", "quantity", "Total List",
      "IPS INVC", "# of ISBNs", "Carton Count", "Carton Charge", "Loose Units", "Loose Charge",
      "SKID CNT", "SKID Charge", "Title Count", "Title Charge", "Total Amount"
    ]
    def self.extract(row)
      description = "Direct Fulfillment"
      ean = nil
      title = nil
      quantity = 0
      amount = BigDecimal(row[-1].to_s)
      Detail.new(ean:, description:, title:, quantity:, amount:)
    end
  end

  module Type4
    # LSIChargesDropShipPrintUK.xlsx
    # LSIChargesPrintToOrderPrinting.xlsx
    HEADINGS = [
      "Invoice Date", "Invoice description", "Invoice Number", "Currency Code", "Invoice Due Date",
      "Bill to Customer Name", "ISBN", "Description", "Quantity Shipped", "Functional Unit Amount",
      "Functional Extended Amount", "Tax Rate", "Tax Amount", "Total"
    ]

    def self.extract(row)
      description = case row[1]
                    when "Inv-PTO" then "Printing"
                    when "Inv-DS"  then "Drop Ship"
                    else
                      raise "Unknown description4 invoice type: #{row[1].inspect}"
                    end

      ean = row[6]
      title = row[7]
      quantity = row[8]
      amount = BigDecimal(row[-1].to_s)
      Detail.new(ean:, description:, title:, quantity:, amount:)
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
      ean = row[0]
      title = row[1]
      quantity = row[12]
      amount = BigDecimal(row[13].to_s)
      Detail.new(ean:, description:, title:, quantity:, amount:)
    end
  end

  ALL_TYPES = [ Type1, Type2, Type3, Type4, AllRevenues ]

  def find_handler_module(headers)
    ALL_TYPES.find do |type|
      type::HEADINGS.zip(headers).all? {|a,b| a == b }
    end || raise("No matching handler found for headers: #{headers}")
  end

  def to_h(handler, row)
    headers = handler::HEADINGS
    fail "Mismatched columns: expected #{headers.size} columns, got #{row.size}" if headers.size != row.size
    Hash[headers.zip(row)]
  end

  def parse(statement, content, file_type)
    sheet = open_spreadsheet(content, file_type)
    sheet.default_sheet = sheet.sheets.first
    next_row = sheet.first_row
    end_row  = sheet.last_row

    headers = sheet.row(next_row)
    handler = find_handler_module(headers)

    next_row += 1
    lines = []

    while next_row <= end_row
      row = sheet.row(next_row)

      result = handler.extract(row)
      hash = to_h(handler, row)

      lines << IpsDetailLine.new(
        content_type: handler.name,
        ean: result.ean,
        title: result.title,
        description: result.description,
        quantity: result.quantity,
        amount: result.amount,
        json: hash.to_json
      )

      next_row += 1
    end
    lines
  end
end

