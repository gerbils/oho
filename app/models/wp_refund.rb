require 'bigdecimal'
require_relative 'wp_order'

WpRefund = Struct.new(
  "WpRefund",
  :id,
  :date_created_gmt,
  :amount,
  :line_items,
  :tax_lines,
  :shipping_lines,
  :fee_lines,
) do

  def self.from_hash(hash)
    new(
      id = hash['id'],
      date_created_gmt: WpOrder::parseAsGmt(hash["date_created_gmt"]),
      amount:           hash["amount"],
      line_items:       hash["line_items"].map { |item| WpRefundLineItem.from_hash(item) },
      tax_lines:        hash["tax_lines"],
      shipping_lines:   hash["shipping_lines"],
      fee_lines:        hash["fee_lines"],
    ).validate!
  end

  def validate!
    sanity("sku", self.sku) { !_1.nil? }
    sanity("format", self.format) { !_1.nil? }

    sanity("quantity", self.quantity) { _1 > 0 }
    sanity("price", self.price) { _1 > 0 }

    self
  end

  private

  def sanity(name, actual, expected= nil, &block)
    ok = if block_given?
           block.call(actual)
         else
           actual == expected
         end
    raise "Invalid line item field #{name}\nexpected: #{expected.inspect}\nactual: #{actual.inspect}\n #{self.inspect}" unless ok
  end
end

