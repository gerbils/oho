module Royalties::Ips; end
module Royalties::Ips::Import
  class Result
    attr_reader :lines
    def initialize
      @lines = {}
    end

    def add(proto_ri)
      sku_id = proto_ri.sku_id
      line = (@lines[sku_id] ||= {})
      channel = proto_ri.description

      if line[channel]
        line[channel].merge(proto_ri)
      else
        line[channel] = proto_ri
      end
      self
    end

    def flatten
      result = []
      @lines.each_value do |channel|
        result.concat(channel.values)
      end
      result
    end
  end
end

module Royalties::Ips::Import
  extend self

  class Totals
    def initialize
      @free_units    = 0
      @paid_units    = 0
      @return_units  = 0
      @paid_amount   = BigDecimal("0.00")
      @return_amount = BigDecimal("0.00")
    end
    attr_accessor :free_units, :paid_units, :return_units, :paid_amount, :return_amount
  end


  MARKETING_AND_MISC = "Distribution: Marketing & Misc."

  def build_royalties_from_details(payment)
    statement_details = payment.ips_statement_details
    non_sku_total = BigDecimal("0.00")
    result = Result.new

    statement_details.each do |detail|
      non_sku_total += accumulate_sku_royalties(detail, result)
    end

    # spread nonspecific costs across all skus
    write_non_sku_values(statement_details, non_sku_total, result) unless non_sku_total.zero?
    create_royalty_items_from(payment, result.flatten)
  end

  def create_royalty_items_from(payment, ri_values)
    now = Time.now

    if ri_values.empty?
      raise "No royalty items found"
    end

    totals = accumulate_totals(ri_values)
    reconcile_ris_with_payment(payment, totals)

    RoyaltyItem.connection.transaction do
      RoyaltyItem.insert_all!(ri_values.map(&:to_h))
      payment.status = IpsPaymentAdvice::STATUS_IMPORTED

      import_summary = ImportSummary.new(
        import_class: payment.class.name,
        import_class_id:    payment.id,
        imported_at:  now,
        import_amount: totals.paid_amount + totals.return_amount,
        notes:        "Imported #{ri_values.size} royalty items from IPS payment advice ##{payment.id}"
      )
      payment.import_summary = import_summary
      payment.save!
    end
  end

  private

  def accumulate_totals(ri_values)
    totals = Totals.new
    ri_values.each do |ri|
      totals.free_units    += ri[:free_units]
      totals.paid_units    += ri[:paid_units]
      totals.return_units  += ri[:return_units]
      totals.paid_amount   += ri[:paid_amount]
      totals.return_amount += ri[:return_amount]
    end
    totals
  end

  def reconcile_ris_with_payment(payment, totals)
    # each detail might be off, so allow for a penny on each
    unless (payment.total_amount - (totals.paid_amount + totals.return_amount)).abs < 0.30
      raise(
        "Net client earnings mismatch—\n" +
        "payment:    #{number_to_currency(payment.total_amount)},\n" +
        "calculated: #{number_to_currency(totals.paid_amount + totals.return_amount)}")
    end
  end


  #
  def accumulate_sku_royalties(detail, result)
    non_sku_total = BigDecimal("0.00")
    lines = detail.ips_detail_lines

    if lines.empty? # no per-sku data (such as COOP)
      non_sku_total = detail.due_this_month
    else
      non_sku_total += accumulate_per_sku_lines(detail, lines, result)
    end
    non_sku_total
  end

  def accumulate_per_sku_lines(detail, lines, result)
    channel = channel_for(detail)
    month = detail.ips_statement.month_ending.strftime("%b '%y")
    non_sku_total = BigDecimal("0.00")
    lines.each do |line|
      if line.sku_id.blank?
        non_sku_total += line.amount
      else
        proto_ri = ProtoRoyaltyLine.new(
          sku_id:        line.sku_id,
          item_type:     RoyaltyItem::IPS_REVENUE_TYPE,
          description:   "#{channel} (#{month})",
          free_units:    0,
          paid_units:    line.quantity,
          paid_amount:   line.amount,
          return_units:  0,
          return_amount: 0,
          book_basis:    0,
          date:          Date.today.strftime("%Y-%m-%d"),
          applies_to:    RoyaltyItem::APPLIES_TO_BOTH,
          source_type:   detail.class.name,
          source_id:     detail.id,
        )
        result.add(proto_ri)
      end
    end
    non_sku_total
  end

  # Any amounts that are not associated with a specific sku are distributed across them all

  def write_non_sku_values(statement_details, total_misc, result)
    skus = Set.new
    statement_details.each do |detail|  # TODO: add a join at some point
      detail.ips_detail_lines.where("sku_id is not null").pluck(:sku_id).uniq.each do |sku_id|
        skus.add(sku_id) unless sku_id.nil?
      end
    end
    return if skus.size.zero?

    a_detail = statement_details.first
    per_sku = (total_misc / skus.size) #.round(2)
    skus.each do |sku_id|
      proto_ri = ProtoRoyaltyLine.new(
        sku_id:        sku_id,
        item_type:     RoyaltyItem::IPS_EXPENSE_TYPE,
        description:   MARKETING_AND_MISC,
        free_units:    0,
        paid_units:    0,
        paid_amount:   0,
        return_units:  0,
        return_amount: per_sku, # + delta,
        book_basis:    0,
        date:          a_detail.month_due,
        applies_to:    RoyaltyItem::APPLIES_TO_BOTH,
        source_type:   a_detail.class.name,
        source_id:     a_detail.id,
      )
      result.add(proto_ri)
    end
  end



  def channel_for(rev_detail)
    case rev_detail.subsection
    when /sales/i
      case rev_detail.detail
      when /canadian/i, /international/i, /UK/
        "Distribution: International Sales"
      when /domestic/i
        "Distribution: Domestic Sales"
      when /ebook/i
        "Distribution: Ebook Sales"
      else
        raise ArgumentError, "Unknown revenue detail #{rev_detail.detail.inspect} for subsection #{rev_detail.subsection.inspect}"
      end
    when /returns/i
      case rev_detail.detail
      when /domestic/i
        "Distribution: Domestic Returns"
      when /international/i
        "Distribution: International Returns"
      when /ebook/i
        "Distribution: Ebook Returns"
      else
        raise ArgumentError, "Unknown revenue detail #{rev_detail.detail.inspect} for subsection #{rev_detail.subsection.inspect}"
      end
    when /freight/i
      "Distribution: Fulfillment"
    when /distribution\s?fees/i
      "Distribution: Fees"
    when /lightning source/i
      "Printing costs"
    when /other fees/i
      MARKETING_AND_MISC
    else
      raise ArgumentError, "Unknown statement detail category #{rev_detail.subsection.inspect}"
    end
  end

end

