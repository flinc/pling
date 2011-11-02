module Pling
  ##
  # This is the base class of all gateways. It defines the public interface of 
  # all gateways and provides helper methods to configure gateways and define
  # the device types a gateway is able to handle.
  #
  # Gateway implementations must set the types they're able to handle by calling
  # the {handles} macro.
  #
  # Every gateway must implement a {#deliver!} method which 
  # does the actual delivering.
  #
  # @example
  #
  #     class Pling::Example::Gateway < Pling::Gateway
  #       handles :example, :foo, :bar
  #
  #       def deliver!(message, device)
  #         puts "Delivering #{message.body} to #{device.identifier} (#{device.type})"
  #       end
  #     end
  class Gateway
    include Pling::Configurable

    class << self
      ##
      # Finds a gateway that handles the given device
      #
      # @param device [#to_pling_device]
      # @raise [Pling::NoGatewayFound] No gateway was found that is able to handle the given device
      # @return [Pling::Gateway] A gateway that handles the given device
      def discover(device)
        device = Pling._convert(device, :device)
        Pling.gateways.initialize!
        Pling.gateways.detect do |gateway|
          gateway.handles?(device)
        end or raise(Pling::NoGatewayFound, "Could not find a gateway for #{device.class} with type :#{device.type}")
      end

      ##
      # Defines the device types a gateway is able to handle
      #
      # @param types [Array<#to_sym>] List of types
      # @return [Array<#to_sym>] List of types
      def handles(*types)
        @handled_types = [types].flatten.map { |t| t.to_sym }
      end

      ##
      # Returns a list of device types that this gateway is able to handle
      #
      # @return [Array<#to_sym>] List of types
      def handled_types
        @handled_types ||= []
      end
    end

    ##
    # Initializes a new Gateway instance
    #
    # @param [Hash] config Configuration for this gateway instance
    # @option config [Array] :middlewares List of middlewares to execute before delivering
    # @option config [#call(exception)] :on_exception Callback to execute when an exception is raised
    def initialize(config = {})
      setup_configuration(config)
      middlewares = configuration[:middlewares]
      configuration.merge!(:middlewares => Pling::DelayedInitializer.new)
      middlewares.each { |middleware| configuration[:middlewares] << middleware } if middlewares
    end

    ##
    # Checks if this gateway is able to handle the given device
    # @param device [#to_pling_device]
    # @return [Boolean]
    def handles?(device)
      device  = Pling._convert(device,  :device)
      self.class.handled_types.include?(device.type)
    end

    ##
    # Delivers the given message to the given device using the given stack.
    # If the :on_exception callback is configured it'll rescue all Pling::Errors
    # and pass them to the given callback.
    #
    # @param message [#to_pling_message]
    # @param device [#to_pling_device]
    # @param stack [Array] The stack to use (Default: configuration[:middlewares])
    # @raise [Pling::DeliveryError] unless configuration[:on_exception] callback is set
    def deliver(message, device, stack = nil)
      message = Pling._convert(message, :message)
      device  = Pling._convert(device,  :device)

      stack ||= [] + configuration[:middlewares].initialize!

      return deliver!(message, device) if stack.empty?

      stack.shift.deliver(message, device) do |m, d|
        deliver(m, d, stack)
      end
    rescue Pling::Error => error
      callback = configuration[:on_exception]
      callback && callback.respond_to?(:call) ? callback.call(error) : raise
    end

    ##
    # Delivers the given message to the given device without using the middleware.
    #
    # @param message [#to_pling_message]
    # @param device [#to_pling_device]
    # @raise [Pling::NotImplementedError] This method must be implemented in subclasses
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
