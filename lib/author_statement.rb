SkuDetail = Struct.new(
  "SkuDetail",
  :prior_totals,
  :month_totals,
  :grand_totals,
  :title,
  :sku,
  :start_of_month,
  :end_of_month,
  :start_of_report,
  :end_of_report,
  :is_editor,
  :royalty_rate,
  :royalty_owed,
)

class Report
  attr_reader :description
  attr_reader :start_of_period
  attr_reader :end_of_period
  attr_reader :start_of_report
  attr_reader :end_of_report

  attr_reader :free_units
  attr_reader :paid_units, :paid_amount
  attr_reader :return_units, :return_amount
  attr_reader :basis
  attr_reader :production_cost
  attr_reader :royalty_owed

  attr_reader :fixed_costs
  attr_reader :royalty_items

  def initialize(
    description,
    start_of_period, end_of_period,
    free_units=0,
    paid_units=0,    paid_amount=0,
    return_units=0,  return_amount=0,
    basis=0,         production_cost=0
  )
    @description = description
    @start_of_report = @start_of_period = start_of_period
    @end_of_report = @end_of_period   = end_of_period
    @free_units = free_units
    @paid_units = paid_units
    @paid_amount = paid_amount
    @return_units = return_units
    @return_amount = return_amount
    @basis = basis
    @production_cost = production_cost
    @royalty_owed = BigDecimal("0.00", 2)
    @fixed_costs = []
    @royalty_items = []
  end

  def net_royalty_based_on
    @paid_amount + @return_amount - @production_cost - total_fixed_costs
  end


  def total_fixed_costs
    @fixed_costs.reduce(BigDecimal("0.00", 2)) do |result, fc|
      result + fc.amount
    end
  end

  def end_of_month
    @end_of_period - 1
  end

  def add_in_report(other)
    @start_of_period  = other.start_of_period if other.start_of_period < @start_of_period
    @end_of_period    = other.end_of_period   if other.end_of_period   > @end_of_period

    if @start_of_report.nil?
      @start_of_report = other.start_of_report
    elsif other.start_of_report
      @start_of_report  = other.start_of_report if other.start_of_report < @start_of_report
    end

    if @end_of_report.nil?
      @end_of_report = other.end_of_report
    elsif other.end_of_report
      @end_of_report  = other.end_of_report if other.end_of_report > @end_of_report
    end

    add_in_numbers(other)
    @royalty_items.concat(other.royalty_items)
    @fixed_costs.concat(other.fixed_costs)
  end

  def add_in_ri(ri, include_actual_ri=false)
    add_in_numbers(ri)
    @start_of_report = ri.date if start_of_report.nil? || ri.date < @start_of_report
    @end_of_report   = ri.date if end_of_report.nil?   || ri.date > @end_of_report
    @royalty_items << ri if include_actual_ri
  end

  def empty?
    @royalty_items.empty? &&
      @fixed_costs.empty? &&
      @paid_amount.zero? &&
      @return_amount.zero?
  end

  private

  def add_in_numbers(other)
    @free_units      += other.free_units
    @paid_units      += other.paid_units
    @paid_amount     += other.paid_amount
    @return_units    += other.return_units
    @return_amount   += other.return_amount
    @production_cost += other.production_cost

    if @paid_units > 0
      @basis = (@production_cost / @paid_units).round(10)
    else
      @basis = 0
    end
  end

end

def fixed_costs(sku, end_date)
  sku.fixed_book_costs.where('created_on < ?', end_date)
end

def ri_list(sku, is_editor, from_date, to_date)
  if is_editor
    sku.royalty_items.for_editors(from_date, to_date)
  else
    sku.royalty_items.for_authors(from_date, to_date)
  end
end

def accumulate_ris(report, sku, is_editor, from_date, to_date, accumulate_ris=false)
  ris = ri_list(sku, is_editor, from_date, to_date)
  ris.each do |ri|
    report.add_in_ri(ri, accumulate_ris)
  end
end

def per_sku_report(author, asr, start_of_month, start_of_next_month)
  sku = asr.sku
  title = sku.product_name
  is_editor = asr.is_editor

  prior_totals = Report.new("Activity prior to #{start_of_month.strftime("%Y-%m")}", start_of_month, start_of_next_month)
  month_totals = Report.new("Activity #{start_of_month.strftime("%B, %Y")}", start_of_month, start_of_next_month)
  grand_totals = Report.new("Totals as of #{(start_of_next_month - 1).strftime("%Y-%m")}", start_of_month, start_of_next_month)

  accumulate_ris(prior_totals, sku, is_editor, Time.at(0), start_of_month, store_ris: false)
  accumulate_ris(month_totals, sku, is_editor, start_of_month, start_of_next_month, store_ris: true)

  # allocate fixed costs

  fixed_costs(sku, end_of_month).each do |fc|
    if fc.created_on < start_of_month
      prior_totals.fixed_costs << fc
    else
      month_totals.fixed_costs << fc
    end
  end

  grand_totals.add_in_report(prior_totals)
  grand_totals.add_in_report(month_totals)

  if grand_totals.empty?
    nil
  else
    SkuDetail.new(
      prior_totals: prior_totals,
      month_totals: month_totals,
      grand_totals: grand_totals,
      title: title,
      sku:   sku,
      start_of_month: start_of_month,
      end_of_month: end_of_month,
      is_editor: is_editor,
      royalty_rate: asr.royalty_percent,
      royalty_owed: grand_totals.net_royalty_based_on * asr.royalty_percent,
      start_of_report: grand_totals.start_of_report,
      end_of_report:   grand_totals.end_of_report,
    )
  end
end

################################################################################

# Royalty period for a month is  >= mon-01 00:00:00 through < (mon+1)-00:00:00
class AuthorStatement

  attr_reader :author
  attr_reader :start_of_month
  attr_reader :end_of_month
  attr_reader :sku_details
  attr_reader :payments
  attr_reader :paid_to_date
  attr_reader :all_titles
  attr_reader :lifetime_royalties_earned
  attr_reader :royalty_owed

  def initialize(author, year, month)
    @author = author
    next_year = year
    next_month = month + 1
    if next_month > 12
      next_month = next_month - 12
      next_year = next_year + 1
    end

    @start_of_month = Time.utc(year, month)
    start_of_next_month = Time.utc(next_year, next_month)
    @lifetime_royalties_earned = BigDecimal("0.00", 2)

    @end_of_month = (Date.new(year, month) >> 1) - 1

    @all_titles = Report.new("All titles", start_of_month, start_of_next_month)

    @sku_details = author.author_sku_royalties.reduce([]) do |result, asr|
      page = per_sku_report(author, asr, @start_of_month, start_of_next_month)

      # page is nil if we're asking for a sku before it has done anyrthing...

      if page
        @lifetime_royalties_earned += page.royalty_owed

        result << page
        @all_titles.add_in_report(page.grand_totals)
      end
      result
    end

    @sku_details = @sku_details.sort_by {|sd| sd.end_of_report}.reverse
    @payments = author.royalties_paid_before(@end_of_month + 1).to_a
    @paid_to_date = @payments.reduce(BigDecimal("0.00", 2)) {|result, pay| result + pay.amount }
    @royalty_owed = @lifetime_royalties_earned - @paid_to_date
  end
end
