class Royalties::BaseController < ApplicationController

  before_action :check_admin

  def check_admin
    unless Current.user&.admin?
      redirect_to root_path, alert: "You must be an admin to access this section."
    end
  end

end
