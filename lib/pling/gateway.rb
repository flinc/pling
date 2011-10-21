module Pling
  module Gateway
    autoload :Base, 'pling/gateway/base'
    autoload :C2DM, 'pling/gateway/c2dm'
    autoload :APN,  'pling/gateway/apn'

    class << self
      def discover(device)
        device = Pling._convert(device, :device)
        Pling.gateways.detect do |gateway|
          gateway.handles?(device)
        end or raise(Pling::NoGatewayFound, "Could not find a gateway for #{device.class} with type :#{device.type}")
      end
    end
  end
end
