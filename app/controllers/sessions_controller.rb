class SessionsController < Devise::SessionsController
  respond_to :json

  def create
    self.resource = warden.authenticate!(auth_options)
    set_flash_message!(:notice, :signed_in)
    sign_in(resource_name, resource)
    yield resource if block_given?

    cookies["X-CSRF-Token"] = {
      value: form_authenticity_token,
      httponly: true,
      secure: Rails.env.production?
    }

    render json: { user: resource, csrf_token: form_authenticity_token }, status: :ok
  end

  def destroy
    super
  end
end
