
class Creators::CreatorsBaseController < OhoApplicationBase

  layout 'application'

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
end

