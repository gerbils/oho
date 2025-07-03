################################################################################

module IpsUploadEstimate
  extend self

  def estimate(statement)
    unless statement.status == IpsStatement::STATUS_UPLOADED
      raise "Can only create royalty estimates for fully-uploaded statements"
    end

    amounts_by_sku = statement.ips_detail_lines.group(:sku_id).sum(:amount)

    rates_by_sku_and_payment_type =
      AuthorSkuRoyalty
      .joins("inner join authors on author_sku_royalties.user_id = authors.user_id")
      .group([:sku_id, :provider_code]).sum(:royalty_percent)
      .each_with_object({}) do |((sku_id, payment_type), rate), h|
        h[sku_id] ||= {}
        h[sku_id][payment_type] = rate
      end

  totals_by_code = {}
    amounts_by_sku.each do |sku_id, amount|
      next if sku_id.nil?
      rates_by_payment_type = rates_by_sku_and_payment_type[sku_id] || {}
      rates_by_payment_type.each do |payment_type, rate|
        totals_by_code[payment_type] ||= { base: BigDecimal("0.00"), extra: BigDecimal("0.00") }
        totals_by_code[payment_type][:base] += amount * rate
      end
    end

    # apportion extra based on ratios of net. This will be negative
    extra = amounts_by_sku[nil] || 0
    total = totals_by_code.values.map {|s| s[:base] }.sum
    totals_by_code.each do |code, amt|
      amt[:extra] = (extra*amt[:base]/total)
      amt[:total] = amt[:base] + amt[:extra]
    end
  end
end
