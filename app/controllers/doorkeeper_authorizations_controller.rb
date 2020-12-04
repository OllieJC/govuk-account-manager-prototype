class DoorkeeperAuthorizationsController < Doorkeeper::AuthorizationsController
  before_action :add_ga_to_redirect_uri

protected

  def add_ga_to_redirect_uri
    if params[:_ga].present? && params[:redirect_uri].present?
      params[:redirect_uri] =
        if params[:redirect_uri].include? "?"
          "#{params[:redirect_uri]}&_ga=#{params[:_ga]}"
        else
          "#{params[:redirect_uri]}?_ga=#{params[:_ga]}"
        end

      @pre_auth = Doorkeeper::OAuth::PreAuthorization.new(
        Doorkeeper.configuration,
        pre_auth_params,
        current_resource_owner,
      )
    end
  end
end
