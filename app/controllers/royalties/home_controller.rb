class Royalties::HomeController < Royalties::BaseController
  def index
    @lp_stats  = LpStatement.stats
    @ips_stats = IpsStatement.stats
  end
end
