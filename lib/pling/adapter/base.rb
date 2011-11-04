module Pling
  module Adapter
    class Base
      include Pling::Configurable

      def initialize(configuration = {})
        setup_configuration(configuration)
      end

      def deliver(message, device)
        Pling.logger.info "#{self.class} -- Delivering #{message.inspect} to #{device.inspect}"

        gateway = Pling::Gateway.discover(device)
        gateway.deliver(message, device)
      end

    end
  end
end