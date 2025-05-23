class Creators::SalesController < Creators::CreatorsBaseController

  def index
    @sales = Authors::SalesData.fetch_for(@effective_user)
  end

  def chart
    sku_id = params[:id]
    @title = params[:title]
    @chart_data = Authors::SalesData.count_by_week_for_sku(@effective_user, sku_id)
    # @min = find_actual_min(@chart_data)
  end

  # private

  # def find_actual_min(data)
  #   [
  #     0,
  #     data[0][:data].values.min,
  #     data[1][:data].values.min,
  #   ]
   # end
end
