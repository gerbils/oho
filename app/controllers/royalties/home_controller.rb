class Royalties::HomeController < Royalties::BaseController
  def index
    @lp_stats = Upload.stats(Upload::CHANNEL_LP)
  end
end
