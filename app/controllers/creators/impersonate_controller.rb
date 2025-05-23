class Creators::ImpersonateController < Creators::CreatorsBaseController
  def index
    @search = params[:search]
    @creators = if !@search || @search.empty?
                  []
                else
                  Authors::Search.all_creators_like(@search)
                end
  end

  def become
    id = params[:id]
    id = nil if id == "stop"
    session[:masquerade] = id
    redirect_to "/"
  end

end
