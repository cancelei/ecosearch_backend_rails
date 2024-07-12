class ApplicationController < ActionController::API
  include ActionController::RequestForgeryProtection
  include ActionController::Cookies
  include Devise::Controllers::Helpers

  protect_from_forgery with: :exception

  before_action :set_csrf_cookie

  private

  def authenticate_user!
    # Custom authentication logic
    head :forbidden unless current_user
  end

  def current_user
    # Logic to retrieve the currently logged in user
    @current_user ||= User.find(session[:user_id]) if session[:user_id]
  end

  def set_csrf_cookie
    cookies["X-CSRF-Token"] = {
      value: form_authenticity_token,
      httponly: true,
      secure: Rails.env.production?
    }
    response.set_header('X-CSRF-Token', form_authenticity_token) if request.format.json?
  end
end
