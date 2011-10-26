module Pling
  module Gateway
    class Base
      include Pling::Configurable

      class << self
        def handles(*types)
          @handled_types = [types].flatten.map { |t| t.to_sym }
        end

        def handled_types
          @handled_types ||= []
        end
      end

      def initialize(configuration = {})
        setup_configuration(configuration)
      end

      def handles?(device)
        self.class.handled_types.include?(device.type)
      end

      ##
      # Delivers the given message to the given device using the given stack.
      #
      # @param message [#to_pling_message]
      # @param device [#to_pling_device]
      # @param stack [Array] The stack to use (Default: configuration[:middlewares])
      def deliver(message, device, stack = [] + configuration[:middlewares])
        message = Pling._convert(message, :message)
        device  = Pling._convert(device,  :device)

        return _deliver(message, device) if stack.empty?

        stack.shift.deliver(message, device) do |m, d|
          deliver(m, d, stack)
        end
      end

      protected

        def _deliver(message, device)
          raise "Please implement #{self.class}#_deliver(message, device)"
        end

        def default_configuration
          {
            :middlewares => []
          }
        end
    end
  end
end
