
class Creators::CreatorsBaseController < ApplicationController

  # layout 'application'
  helper_method :menu_name

  before_action do
    @app_title = "Pragmatic Creators"
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

  protected

  def menu_name
    "creators/creators_base/top_menu"
  end
end

