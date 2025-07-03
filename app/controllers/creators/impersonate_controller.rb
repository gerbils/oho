class Creators::ImpersonateController < Creators::CreatorsBaseController
  def index
    @creators = search_for_creators
  end

  def incremental_search
    creators = search_for_creators

  end

  def become
    id = params[:id]
    id = nil if id == "stop"
    session[:masquerade] = id
    redirect_to "/"
  end

  def search_for_creators
    @search = params[:search]
    if !@search || @search.empty?
      []
    else
      Authors::Search.all_creators_like(@search)
    end
  end
end
