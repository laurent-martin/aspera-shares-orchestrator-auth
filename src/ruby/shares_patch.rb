# BEGIN PATCH
require 'special_shares_auth'
if __FILE__.end_with?('/base_controller.rb')
  # /opt/aspera/shares/u/shares/app/controllers/api/base_controller.rb
  # API : authenticate (have user object)
  unless user.saml?
    error_message = SpecialSharesAuth.check_auth(user.name, request.ip)
    if error_message
      render json: ApiError.new(user_message: error_message), status: :unauthorized
      return
    end
  end
elsif __FILE__.end_with?('/sessions_controller.rb')
  # /opt/aspera/shares/u/shares/app/controllers/sessions_controller.rb
  # web : create (only non-saml)
  error_message = SpecialSharesAuth.check_auth(params[:username], request.ip)
  if error_message
    flash.now[:error] = error_message
    render :new
    return
  end
end
# END PATCH
