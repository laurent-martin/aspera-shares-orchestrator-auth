# BEGIN PATCH
# frozen_string_literal: true

# This code is added to:
# /opt/aspera/shares/u/shares/app/controllers/sessions_controller.rb : create
# /opt/aspera/shares/u/shares/app/controllers/api/base_controller.rb : authenticate

require 'special_shares_auth'
error_message = SpecialSharesAuth.check_auth(__method__.eql?(:authenticate) ? user.name : params[:username], request.ip)
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
