# app/controllers/users/registrations_controller.rb
class Users::RegistrationsController < Devise::RegistrationsController
  respond_to :json
  before_action :configure_sign_up_params, only: [:create]

  def create
    super do
      set_default_nickname
      resource.save
    end
  end

  private

  def set_default_nickname
    resource.nickname = params[:user][:login]
  end

  def configure_sign_up_params
    devise_parameter_sanitizer.permit(:sign_up, keys: [:login])
  end

  def respond_with(resource, _opts = {})
    register_success && return if resource.persisted?

    register_failed
  end

  def register_success
    render json: {
      message: 'Signed up sucessfully.',
      user: current_user
    }, status: :ok
  end

  def register_failed
    render json: { message: 'Something went wrong.' }, status: :unprocessable_entity
  end
end
