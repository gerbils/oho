
module Helpers::DateTime

  def first_of_month(date)
    @date_map ||= {}
    @date_map[date] ||= Date.new(date.year, date.month, 1)
  end

end
