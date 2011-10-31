module Pling
  class Gateway
    include Pling::Configurable

    class << self
      def discover(device)
        device = Pling._convert(device, :device)
        Pling.gateways.initialize!
        Pling.gateways.detect do |gateway|
          gateway.handles?(device)
        end or raise(Pling::NoGatewayFound, "Could not find a gateway for #{device.class} with type :#{device.type}")
      end

      def handles(*types)
        @handled_types = [types].flatten.map { |t| t.to_sym }
      end

      def handled_types
        @handled_types ||= []
      end
    end

    def initialize(config = {})
      setup_configuration(config)
      middlewares = configuration[:middlewares]
      configuration.merge!(:middlewares => Pling::DelayedInitializer.new)
      middlewares.each { |middleware| configuration[:middlewares] << middleware } if middlewares
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
    def deliver(message, device, stack = nil)
      message = Pling._convert(message, :message)
      device  = Pling._convert(device,  :device)

      stack ||= [] + configuration[:middlewares].initialize!

      return deliver!(message, device) if stack.empty?

      stack.shift.deliver(message, device) do |m, d|
        deliver(m, d, stack)
      end
    end

    ##
    # Delivers the given message to the given device without using the middleware.
    #
    # @param message [#to_pling_message]
    # @param device [#to_pling_device]
    def deliver!(message, device)
      raise NotImplementedError, "Please implement #{self.class}#deliver!(message, device)"
    end

    protected

      def default_configuration
        {
          :middlewares => Pling::DelayedInitializer.new
        }
      end
  end
end
