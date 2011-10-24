module Pling
  module Adapter
    class Base
      include Pling::Configurable

      def initialize(configuration = {})
        setup_configuration(configuration)
      end

      def deliver(message, device)
        gateway = Pling::Gateway.discover(device)
        gateway.deliver(message, device)
      end

    end
  end
end