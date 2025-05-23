class OhoApplicationBase < ActionController::Base
  before_action :set_current_request_details
  before_action :authenticate

  private
    def authenticate
      if session_record = Session.find_by_id(cookies.signed[:session_token])
        Current.session = session_record
      else
        # if Rails.env.development?
        #   user = User.find(5)
        #   @session = user.sessions.create!
        #   cookies.signed.permanent[:session_token] = { value: @session.id, httponly: true }
        #   Current.session = @session
        # Rails.logger.info("created #{@session.inspect}")
        # else
          redirect_to  sign_in_path
        # end
      end
    end

    def set_current_request_details
      Current.user_agent = request.user_agent
      Current.ip_address = request.ip
    end
end

