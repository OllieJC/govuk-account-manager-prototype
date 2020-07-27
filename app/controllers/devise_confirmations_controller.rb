class DeviseConfirmationsController < Devise::ConfirmationsController
  def sent
    @email = params[:email]
  end

  # POST /resource/confirmation
  # Taken from (https://github.com/heartcombo/devise/blob/715192a7709a4c02127afb067e66230061b82cf2/app/controllers/devise/confirmations_controller.rb)
  def create
    self.resource = resource_class.send_confirmation_instructions(resource_params)
    yield resource if block_given?

    if successfully_sent?(resource)
      respond_with({}, location: after_resending_confirmation_instructions_path_for(resource.email))
    else
      respond_with(resource)
    end
  end

protected

  def after_resending_confirmation_instructions_path_for(resource_email)
    confirmation_sent_path(email: resource_email)
  end
end