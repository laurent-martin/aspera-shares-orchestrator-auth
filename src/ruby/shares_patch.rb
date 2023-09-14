# BEGIN PATCH
# This code is added to /opt/aspera/shares/u/shares/app/controllers/sessions_controller.rb
# frozen_string_literal: true

error_message = nil
begin
  require 'special_shares_auth'
  error_message = SpecialSharesAuth.check_auth(params[:username], request.ip)
  if error_message
    flash.now[:error] = error_message
    render :new
    return
  end
rescue Exception => e # rubocop:disable Lint/RescueException
  error_message = "Error: #{e}"
end
if error_message
  flash.now[:error] = error_message
  render :new
  return
end
# END PATCH
