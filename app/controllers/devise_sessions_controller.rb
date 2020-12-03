class DeviseSessionsController < Devise::SessionsController
  include ApplicationHelper
  include CookiesHelper

  before_action :check_login_state, only: %i[
    phone_code
    phone_verify
    phone_resend
  ]

  before_action :check_password_ok, only: %i[
    phone_code
    phone_verify
    phone_resend
  ]

  def create
    payload = ApplicationKey.validate_jwt!(params[:jwt]) if params[:jwt]

    render :new and return unless params.dig(:user, :email) || params.dig(:user, :password)

    @email = params.dig(:user, :email)
    catch(:warden) do
      self.resource = warden.authenticate(auth_options)
    end

    if resource
      @login_state = create_login_state(payload, @email, password_ok: true)
      @login_state_id = login_state.id
      session[:login_state_id] = login_state.id

      if request.env["warden.mfa.required"]
        MultiFactorAuth.generate_and_send_code(resource)
        redirect_to user_session_phone_code_path
      else
        do_sign_in
      end
    else
      @resource_error_messages = {}

      @resource_error_messages[:email] = if @email.blank?
                                           [I18n.t("activerecord.errors.models.user.attributes.email.blank")]
                                         elsif !Devise.email_regexp.match? @email
                                           [I18n.t("activerecord.errors.models.user.attributes.email.invalid")]
                                         end

      if params.dig(:user, :password).blank?
        @resource_error_messages[:password] = [I18n.t("activerecord.errors.models.user.attributes.password.blank")]
      end

      user = User.find_by(email: @email)
      user_exists = user.present?

      if user_exists && !user.active_for_authentication?
        @resource_error_messages[:email] = [I18n.t("devise.failure.unconfirmed")]
      end

      if @email.present? && params.dig(:user, :password).present? && user_exists
        @resource_error_messages[:password] = case user&.unauthenticated_message # pragma: allowlist secrets
                                              when :last_attempt
                                                [I18n.t("devise.failure.last_attempt")]
                                              when :locked
                                                [I18n.t("devise.failure.locked")]
                                              when :invalid
                                                [I18n.t("devise.failure.invalid")]
                                              end
      elsif @email.present? && params.dig(:user, :password).blank? && user_exists
        @resource_error_messages[:password] = [I18n.t("activerecord.errors.models.user.attributes.password.blank")]
      elsif @email.present?
        render "devise/registrations/transition_checker" and return
      end

      render :new and return if @resource_error_messages.present?
    end
  end

  def phone_code; end

  def phone_verify
    state = MultiFactorAuth.verify_code(login_state.user, params[:phone_code])
    if state == :ok
      do_sign_in
      login_state.user.update!(last_mfa_success: Time.zone.now)
      login_state.destroy!
      session.delete(:login_state_id)
    else
      @phone_code_error_message = I18n.t("mfa.errors.phone_code.#{state}", resend_link: user_session_phone_resend_path)
      render :phone_code
    end
  end

  def phone_resend; end

  def destroy
    redirect_to account_delete_confirmation_path and return if params[:done] == "delete"
    redirect_to transition_path and return if all_signed_out?

    if params[:continue]
      current_user.invalidate_all_sessions!
      Devise.sign_out_all_scopes ? sign_out : sign_out(resource_name)
      redirect_to "#{transition_checker_path}/logout?done=#{params[:continue]}"
    elsif params[:done]
      current_user.invalidate_all_sessions!
      super
    else
      redirect_to "#{transition_checker_path}/logout?continue=1"
    end
  end

protected

  def verify_signed_out_user; end

  def check_login_state
    @login_state_id = session[:login_state_id]
    redirect_to user_session_path unless login_state
  end

  def check_password_ok
    redirect_to user_session_path unless login_state.password_ok
  end

  def after_login_path(payload, user)
    payload&.dig(:post_login_oauth).presence || after_sign_in_path_for(user)
  end

  def create_login_state(payload, email, password_ok = false)
    user = User.find_by(email: email).id

    LoginState.create!(
      created_at: Time.zone.now,
      user_id: user,
      redirect_path: after_login_path(payload, user),
      password_ok: password_ok,
    )
  end

  def login_state
    @login_state ||=
      begin
        LoginState.find(@login_state_id)
      rescue ActiveRecord::RecordNotFound # rubocop:disable Lint/SuppressedException
      end
  end

  def do_sign_in
    cookies[:cookies_preferences_set] = "true"
    response["Set-Cookie"] = cookies_policy_header(login_state.user)

    sign_in(resource_name, login_state.user)
    redirect_to login_state.redirect_path
  end

  def after_sign_out_path_for(_resource)
    transition_path
  end
end
