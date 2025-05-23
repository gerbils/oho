require 'bigdecimal'
 # "line_items": [
 #    {
 #      "id": 32,
 #      "name": "Concurrent Data Processing in Elixir - eBook",
 #      "product_id": 81,
 #      "variation_id": 84,
 #      "quantity": 0,
 #      "tax_class": "",
 #      "subtotal": "-10.00",
 #      "subtotal_tax": "0.00",
 #      "total": "-10.00",
 #      "total_tax": "0.00",
 #      "taxes": [],
 #      "meta_data": [
 #        {
 #          "id": 210,
 #          "key": "_refunded_item_id",
 #          "value": "29",
 #          "display_key": "_refunded_item_id",
 #          "display_value": "29"
 #        }
 #      ],
 #      "sku": "SGDPELIXIR-P-00",
 #      "price": 0,
 #      "image": {
 #        "id": 82,
 #        "src": "https://wp.ppstage.dev/wp-content/uploads/2025/02/sgdpelixir.png"
 #      },
 #      "parent_name": "Concurrent Data Processing in Elixir"
 #    }
 #  ],

WpRefundLineItem = Struct.new(
  "WpLineItem",
  :line_item_id,
  :sku,
  :quantity,
  :total,
) do


  def self.from_hash(hash)
    new(
      id:            get_line_item_id(hash),
      sku:           hash['sku'],
      quantity:      Integer(hash['quantity']),
      total:         BigDecimal(hash['total'], 4),
    )
  end

  private

  def self.get_line_item_id(hash)
    md_item = hash['meta_data'].find { |meta| meta['key'] == '_refunded_item_id' }
    fail("Cannot find _refunded_item_id in #{hash}") unless md_item
    md_item['value'] || raise("Cannot find _refunded_item_id.value in #{hash}")
  end
end
