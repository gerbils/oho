require 'bigdecimal'
WpOrder = Struct.new(
  :cart_tax,
  :coupon_lines,
  :date_completed_gmt,
  :date_created_gmt,
  :date_modified_gmt,
  :date_paid_gmt,
  :discount_tax,
  :discount_total,
  :fee_lines,
  :id,
  :line_items,
  :needs_payment,
  :needs_processing,
  :refunds,
  :shipping_lines,
  :shipping_tax,
  :shipping_total,
  :status,
  :tax_lines,
  :total,
  :total_tax,
) do

  EXPECTED_DTM_LENGTH = "2025-02-15T23:11:57".length

  # woo dates are in GMT, but lack a trailing timesonze, so the RUby
  # dqte parses assume they are in the local timezone...
  def self.parse_as_gmt(date)
    return nil if date.nil?
    if date.length != EXPECTED_DTM_LENGTH
      fail "Invalid date (should be yyyy-mm-ddThh:mm:ss): #{date}"
    end
    Time.strptime(date + "Z", "%Y-%m-%dT%H:%M:%S%Z")
  end

  # encode the JSON returns from the rest API
  def self.from_hash(json)
    new(
    cart_tax:           BigDecimal(json['cart_tax'], 4),
    coupon_lines:       json["coupon_lines"],
    date_completed_gmt: parse_as_gmt(json['date_completed_gmt']),
    date_created_gmt:   parse_as_gmt(json['date_created_gmt']),
    date_modified_gmt:  parse_as_gmt(json['date_modified_gmt']),
    date_paid_gmt:      parse_as_gmt(json['date_paid_gmt']),
    discount_tax:       BigDecimal(json['discount_tax'], 4),
    discount_total:     BigDecimal(json['discount_total'], 4),
    fee_lines:          json["fee_lines"],
    id:                 json['id'],
    line_items:         json['line_items'].map { |item| WpLineItem.from_hash(item) },
    needs_payment:      json["needs_payment"],
    needs_processing:   json["needs_processing"],
    refunds:            json["refunds"],
    shipping_lines:     json["shipping_lines"],
    shipping_tax:       BigDecimal(json['shipping_tax'], 4),
    shipping_total:     BigDecimal(json['shipping_total'], 4),
    status:             json['status'],
    tax_lines:          json["tax_lines"],
    total:              BigDecimal(json['total'], 4),
    total_tax:          BigDecimal(json['total_tax'], 4)
    )#.validate!
  end

  def validate!
    sanity("parent_id", self.parent_id, 0)
    sanity("currency", self.currency, "USD")
    self
  end

  private

  def sanity(json, actual, expected)
    raise "Invalid order: #{self.inspect}" unless actual == expected
  end
end
