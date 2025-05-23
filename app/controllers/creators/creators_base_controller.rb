
class Creators::CreatorsBaseController < ApplicationController

  before_action do
    @app_title = "Pragmatic Creators"
    @oho_top_menu = "creators/top_menu"
  end

  append_before_action do
    if session[:masquerade]
      @effective_user = User.find_by_id(session[:masquerade])
      if @effective_user.nil?
        @effective_user = Current.user
        session[:masquerade] = nil
      end
    else
      @effective_user = Current.user
    end
  end

end

