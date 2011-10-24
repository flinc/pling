module Pling
  module Middleware
    class Base
      include Pling::Configurable

      def initialize(configuration = {})
        setup_configuration(configuration)
      end

      def deliver(message, device)
        yield(message, device)
      end
    end
  end
end