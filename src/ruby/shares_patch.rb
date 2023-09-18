# BEGIN PATCH
# frozen_string_literal: true

# This code is added to:
# /opt/aspera/shares/u/shares/app/controllers/sessions_controller.rb : web : create (only non-saml)
# /opt/aspera/shares/u/shares/app/controllers/api/base_controller.rb : API : authenticate (have user object)

require 'special_shares_auth'
error_message =
  if __method__.eql?(:authenticate)
    if user.saml?
      nil
    else
      SpecialSharesAuth.check_auth(user.name, request.ip)
    end
  else
    SpecialSharesAuth.check_auth(params[:username], request.ip)
  end

if error_message
  if __method__.eql?(:authenticate)
    render json: ApiError.new(user_message: error_message), status: :unauthorized
  else
    flash.now[:error] = error_message
    render :new
  end
  return
end
# END PATCH
