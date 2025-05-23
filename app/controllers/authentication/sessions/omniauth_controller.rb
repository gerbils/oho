module Authentication
  module Sessions
    class OmniauthController < ApplicationController
      skip_before_action :verify_authenticity_token
      skip_before_action :authenticate

      def create
        # @user = User.create_with(user_params).find_or_initialize_by(omniauth_params)

        @user = User.find_by_id(omniauth.uid)
        if @user
          unless @user.author_details
            redirect_to login_path
          else
            session_record = @user.sessions.create!
            cookies.signed.permanent[:session_token] = { value: session_record.id, httponly: true }
            redirect_to root_path,    notice: "Signed in successfully"
          end
        else
          redirect_to login_path, alert: "Authentication failed"
        end
      end

      def failure
        redirect_to login_path, alert: params[:message]
      end

      private

      def omniauth
        request.env["omniauth.auth"]
      end

      # def user_params
      #   { email: omniauth.info.email, password: SecureRandom.base58, verified: true }
      # end

      # def omniauth_params
      #   { provider: omniauth.provider, uid: omniauth.uid }
      # end

    end
  end
end
