class ApplicationController < ActionController::Base
  include Authentication
  helper_method :menu_name
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  protected

  def menu_name
    "creators_base/top_menu"
  end
end
