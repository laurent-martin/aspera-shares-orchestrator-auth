# BEGIN PATCH
# /opt/aspera/shares/u/shares/app/controllers/login_base_controller.rb
# web : create (only non-saml)
require 'special_shares_auth'
unless user.saml?
  error_message = SpecialSharesAuth.check_auth(user.name, request.ip)
  if error_message
    login_failure(error_message)
    return
  end
end
# END PATCH
