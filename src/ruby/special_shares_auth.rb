# frozen_string_literal: true

require 'net/http'
require 'openssl'
require 'json'
# rubocop:disable Lint/RescueException
# rubocop:disable Style/RedundantBegin
# rubocop:disable Metrics/MethodLength
# rubocop:disable Metrics/AbcSize
# This class is used to authenticate users against a remote system.
class SpecialSharesAuth
  class << self
    def check_auth(user, ip)
      begin
        @config = JSON.parse(File.read(__FILE__.gsub(/\.rb$/, '.json'))) if @config.nil?
        orch_url = @config['url']
        # API parameters
        params = {
          login: @config['user'],
          password: @config['pass'],
          id: @config['workflow'],
          synchronous: true,
          format: 'json'
        }
        # workflow parameters
        external_parameters = {
          username: user,
          ipaddress: ip
        }
        external_parameters.each do |key, value|
          params["external_parameters[#{key}]"] = value
        end
        orch_uri = URI.parse("#{orch_url}/api/initiate?#{URI.encode_www_form(params)}")
        http_connection = Net::HTTP.new(orch_uri.host, orch_uri.port)
        http_connection.use_ssl = true
        http_connection.verify_mode = OpenSSL::SSL::VERIFY_NONE
        http_request = Net::HTTP::Get.new(orch_uri)
        http_response = http_connection.request(http_request)
        raise "Validation Error: #{http_response.code}" unless http_response.code == '200'

        result = JSON.parse(http_response.body)
        work_order = result['work_order']
        return nil if work_order['status'] == 'Complete'
        return work_order['statusDetails'] if work_order['status'] == 'Failed'

        raise "#{work_order['status']}: #{work_order['statusDetails']}"
      rescue Exception => e
        "Error in Special Auth: #{e}"
      end
    end
  end
end
# rubocop:enable all

# msg = SpecialSharesAuth.check_auth('admin', '192.168.0.0')
# puts("msg: #{msg}")