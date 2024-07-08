# app/controllers/registrations_controller.rb
class RegistrationsController < Devise::RegistrationsController
  # If you have any custom behavior, add it here.
  # For example, permit additional parameters:
  before_action :configure_sign_up_params, only: [:create]

  protected

  def configure_sign_up_params
    devise_parameter_sanitizer.permit(:sign_up, keys: [:attribute1, :attribute2])
  end
end
