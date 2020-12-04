class DoorkeeperAuthorizationsController < Doorkeeper::AuthorizationsController
  include UrlHelper

  before_action :add_ga_to_redirect_uri

protected

  def add_ga_to_redirect_uri
    if params[:redirect_uri].present?
      params[:redirect_uri] = add_param_to_url(params[:redirect_uri], "_ga", params[:_ga])

      @pre_auth = Doorkeeper::OAuth::PreAuthorization.new(
        Doorkeeper.configuration,
        pre_auth_params,
        current_resource_owner,
      )
    end
  end
end
