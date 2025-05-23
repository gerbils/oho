class Creators::RoyaltiesController < Creators::CreatorsBaseController
  # before_action :require_login
  # before_action :require_author

  # GET /royalties
  # GET /royalties.json
  def index
    @effective_user = current_user.effective_user
    @royalty_dates = @effective_user.find_available_royalty_dates
  end

  # GET /royalties/:year/:month
  # GET /royalties/:year/:month.json
  def index
    @name = @effective_user.author_details.name
    dates = @effective_user.find_available_royalty_dates
    @date_map = {}
    dates.each do |date|
      (@date_map[date.year] ||= []) << date.month
    end
  end

  def show
    year  = params[:year].to_i    # no need to sanitize across to_i ?
    month = params[:month].to_i
    @rs = ::AuthorStatement.new(@effective_user, year, month)
    @author = @effective_user.author_details
    # @summary      = rs.summary
    # @pages        = rs.pages.sort_by {|page| page.title_name }
    # @paid_to_date = rs.paid_to_date
    @max_page     = @rs.sku_details.size + 1
  end

end
