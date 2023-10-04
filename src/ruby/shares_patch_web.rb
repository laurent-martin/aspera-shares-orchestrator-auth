# BEGIN PATCH
# /opt/aspera/shares/u/shares/app/controllers/sessions_controller.rb
# web : create (only non-saml)
require 'special_shares_auth'
unless user.saml?
  error_message = SpecialSharesAuth.check_auth(user.name, request.ip)
  if error_message
    flash.now[:error] = error_message
    render :new
    return
  end
end
# END PATCH
