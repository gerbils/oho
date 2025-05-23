require 'bigdecimal'
require_relative 'wp_order'

WpLineItem = Struct.new(
  "WpLineItem",
  :id,
  :sku,
  :quantity,
  :price,
  :subtotal,
  :subtotal_tax,
  :total,
  :total_tax,
  :taxes,
  :format,
) do

  # id	          integer	  Item ID.read-only
  # name	        string	  Product name.
  # product_id	  integer	  Product ID.
  # variation_id	integer	  Variation ID, if applicable.
  # quantity	    integer	  Quantity ordered.
  # tax_class	  string	  Slug of the tax class of product.
  # subtotal	    string	  Line subtotal (before discounts).
  # subtotal_tax	string	  Line subtotal tax (before discounts).read-only
  # total	      string	  Line total (after discounts).
  # total_tax	  string	  Line total tax (after discounts).read-only
  # taxes	      array	    Line taxes. See Order - Tax lines propertiesread-only
  # meta_data	  array	    Meta data. See Order - Meta data properties
  # sku	        string	  Product SKU.read-only
  # price	      string	  Product price.

  def self.from_hash(hash)
    new(
      id:            hash['id'],
      sku:           hash['sku'],
      quantity:      Integer(hash['quantity']),
      price:         BigDecimal(hash['price'], 4),
      subtotal:      BigDecimal(hash['subtotal'], 4),
      subtotal_tax:  BigDecimal(hash['subtotal_tax'], 4),
      total:         BigDecimal(hash['total'], 4),
      total_tax:     BigDecimal(hash['total_tax'], 4),
      taxes:         hash['taxes'],
      format:        hash['meta_data'].find do |meta|
        meta['key'] == 'pa_format'
      end&.dig('display_value')
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
