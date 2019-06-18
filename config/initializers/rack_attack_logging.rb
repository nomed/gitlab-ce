# frozen_string_literal: true
#
# Adds logging for all Rack Attack blocks and throttling events.

ActiveSupport::Notifications.subscribe('rack.attack') do |name, start, finish, request_id, req|
  if [:throttle, :blacklist].include? req.env['rack.attack.match_type']
    rack_attack_info = {
      message: 'Rack_Attack',
      env: req.env['rack.attack.match_type'],
      ip: req.ip,
      request_method: req.request_method,
      fullpath: req.fullpath
    }

    if req.env['rack.attack.matched'] != 'throttle_unauthenticated'
      rack_attack_info[:user_id] = req.env['rack.attack.match_discriminator']
    end

    Gitlab::AuthLogger.error(rack_attack_info)
  end
end
