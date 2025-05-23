module Authors::SalesData
  extend self

  Sales = Struct.new("SalesData", :sku, :direct_units, :channel_units, :return_units) do
    def total_units
      self.direct_units + self.channel_units + self.return_units
    end
  end

  def fetch_for(user)
    data = {}
    user.skus.each do |sku|
      data[sku.id] = Sales.new(sku, 0, 0, 0)
    end

    items = LineItem.find_by_sql(["select li.sku_id as sku_id,
                                          sum(li.quantity) as quantity
                                     from line_items li, orders o
                                    where li.order_id = o.id
                                      and o.when_billed is not null
                                      and o.type = 'PlacedOrder'
                                      and li.sold_at_price > 0
                                      and li.sku_id in (?)
                                    group by 1",
                                    data.keys])

    items.each do |item|
      data[item.sku_id].direct_units = Integer(item.quantity || "0")
    end

    channel_sales = OraRawDatum.find_by_sql(["select sku_id,
                                                    sum(gross_units) as channel,
                                                    sum(return_units) as returns
                                                    from ora_raw_data
                                                    where sku_id in (?)
                                                    group by 1", data.keys])
    channel_sales.each do |sale|
      data[sale.sku_id].channel_units = sale.channel.to_i
      data[sale.sku_id].return_units = sale.returns.to_i
    end

    data.values
  end

  def count_by_week_for_sku(user, sku_id)
    _sku = user.skus.find(sku_id)  # verify user owns sku

    result = []

    [ :group_by_month, :group_by_week, :group_by_day ].each do |grouping_interval|

      online = LineItem
        .joins(:order)
        .where("orders.when_billed is not null and orders.type = 'PlacedOrder'")
        .where("sold_at_price > 0")
        .where(sku_id: sku_id)
        .send(grouping_interval, :when_billed)
        .sum(:quantity)

      channel = OraRawDatum
        .where(sku_id: sku_id)
        .send(grouping_interval, :post_date)
        .sum("gross_units + return_units")

      next if grouping_interval != :group_by_day && ((online.count > 0 && online.count < 12) || (channel.count > 0 && channel.count < 12))

      return [
        {
          name: "Direct sales (units)",
          data: skip_zeros(online),
          tension: 0,
        },
        {
          name: "Channel sales (units)",
          data: skip_zeros(channel),
          tension: 0,
        },
      ]
    end
  end

  private

  def skip_zeros(data_hash)
    state = :copying
    data = data_hash.to_a

    result = []

    while data.length > 1
      date, value = entry = data.shift

      case state
      when :copying
        result << entry
        if value.zero?
          state = :first_zero_copied
        end

      when :first_zero_copied
        if !value.zero?
          result << entry
          state = :copying
        end
        state = :skipped_a_zero
        last_entry = entry

      when :skipped_a_zero
        if value.zero?
          last_entry = entry
        else
          result << last_entry
          result << entry
          state = :copying

        end
      end
    end

    if data.length > 0
      result << data.shift
    end

    result.to_h

  end

end

