require 'debug'

class Authentication::SessionsController < ApplicationController
  before_action :authenticate, except: %i[ new create ]
  before_action :set_session, only: :destroy

  def index
    @sessions = Current.user.sessions.order(created_at: :desc)
  end

  def new
    Sentry::Metrics.increment('login.start')
  end

  def create
    redirect_uri = session[:redirect_uri]

    user = User.find_by(email: params[:email])&.authenticate(params[:password])
    if !user
      Sentry::Metrics.increment('login.bad_email_password')
      redirect_to sign_in_path(email_hint: params[:email]), alert: "That email or password is incorrect"
    elsif Rails.configuration.x.oho.admin_only && !user.admin?
      Sentry::Metrics.increment('login.not admin')
      redirect_to sign_in_path(email_hint: params[:email]), alert: "Access not granted"
    elsif !user.is_author_or_above?
      Sentry::Metrics.increment('login.not author_or_above')
      redirect_to sign_in_path(email_hint: params[:email]), alert: "Access not granted"
    else
      @session = user.sessions.create!
      cookies.signed.permanent[:session_token] = { value: @session.id, httponly: true }

      Sentry::Metrics.increment('login.success')

      if redirect_uri
        session.delete(:redirect_uri)
        redirect_to redirect_uri, s: @session.id, allow_other_host: true
      else
        redirect_to root_path, notice: "Signed in successfully"
      end
    end
  end

  def destroy
    @session.destroy
    redirect_to(sessions_path, notice: "Logged out")
  end

  def logout_all
    count = 0
    query = Current.user.sessions
    unless params[:all_ips]
      query = query.where(ip_address: Current.ip_address)
    end

    query.each do |session|
      count += 1
      session.destroy
    end
    redirect_to(sessions_path, notice: "Logged out of #{count} session#{ count == 1 ? '' : 's' }")
  end

  private
    def set_session
      @session = Current.user.sessions.find(params[:id])
    end
end
