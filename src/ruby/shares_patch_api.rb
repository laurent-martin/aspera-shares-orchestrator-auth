# BEGIN PATCH
# /opt/aspera/shares/u/shares/app/controllers/api/base_controller.rb
# API : authenticate (have user object)
require 'special_shares_auth'
error_message = SpecialSharesAuth.check_auth(user, request.ip)
if error_message
  render json: ApiError.new(user_message: error_message), status: :unauthorized
  return
end
# END PATCH
