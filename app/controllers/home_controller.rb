class HomeController < ApplicationController
  def index
    case
    when Current.user.admin?
      render :index
    when Current.user.author?,
      Current.user.editor?,
      Current.user.series_editor?
      redirect_to creators_root_url
    else
      Current.user.sessions.each {|session| session.destroy }
      cookies.delete(:session_token)
      redirect_to sign_in_url, alert: "Access not granted"
    end
  end
end
