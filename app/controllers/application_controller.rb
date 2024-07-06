class ApplicationController < ActionController::API
  include ActionController::RequestForgeryProtection
  include ActionController::Cookies
  include Devise::Controllers::Helpers

  protect_from_forgery with: :null_session

  before_action :set_csrf_cookie

  private

  def authenticate_user!
    # Custom authentication logic
    redirect_to login_path unless current_user
  end

  def current_user
    # Logic to retrieve the currently logged in user
    @current_user ||= User.find(session[:user_id]) if session[:user_id]
  end

  def set_csrf_cookie
    cookies["CSRF-TOKEN"] = {
      value: form_authenticity_token,
      secure: Rails.env.production?
    }
  end
end
