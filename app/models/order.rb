class Order < LegacyRecord
  has_many :line_items, dependent: :destroy
  has_many :skus, through: :line_items
  has_many :discount_items
  has_many :comments,
    -> { order("created_at asc")  },
    :dependent => :delete_all, :class_name => "OrderComment"

  # belongs_to :shopify_ingest_batch, optional: true
  #
  # def self.shopify_number_to_pip_number(n)
  #   n
  # end
  #
  #
  # def self.from_shopify_number(n)
  #   where(number: shopify_number_to_pip_number(n)).first
  # end
  #
  def imported_into_royalties?
    !!self.imported_into_royalties_at
  end

  def calculate_list_discount_item_total
    discounted_items = discount_items.select {|di| di.discount?}
    discounted_items.inject(BigDecimal("0.00")) {|sum, di| sum + di.total_amount}
  end

  def calculate_line_item_total
    line_items.inject(BigDecimal("0.00")) {|sum, item| sum + item.total_price }
  end

  def calculate_discount_item_total
    discount_items.inject(BigDecimal("0.00")) { |sum, di| sum + di.total_amount }
  end


  def calc_totals_with_external_tax(tax_amt)
    self.product_total   = calculate_line_item_total
    self.discount_total  = calculate_discount_item_total
    @list_discount_total = calculate_list_discount_item_total
    sub_total           = self.product_total + self.discount_total + self.shipping_total
    self.tax_total      = tax_amt
    self.grand_total    = sub_total + self.tax_total
  end

end
