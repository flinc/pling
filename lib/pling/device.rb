module Pling
  class Device

    ##
    # The device identifier
    #
    # @overload identifier
    # @overload identifier=(identifier)
    #   @param [#to_s] identifier
    attr_reader :identifier

    def identifier=(identifier)
      identifier &&= identifier.to_s
      @identifier = identifier
    end

    ##
    # The device type
    #
    # @overload type
    # @overload type=(type)
    #    @param [#to_sym] type
    attr_reader :type

    def type=(type)
      type &&= type.to_sym
      @type = type
    end

    ##
    # Creates a new Pling::Device instance with the given identifier and type
    #
    # @param [Hash] attributes
    # @option attributes [#to_s] :identifier
    # @option attributes [#to_sym] :type
    def initialize(attributes = {})
      attributes.each_pair do |key, value|
        method = "#{key}="
        send(method, value) if respond_to?(method)
      end
    end

    ##
    # A device is valid if it has a type and an identifier.
    #
    # @return [Boolean]
    def valid?
      !!(type && identifier)
    end

    ##
    # Delivers the given message using an appropriate gateway.
    #
    # @param [#to_pling_message] message
    def deliver(message)
      Pling.deliver(message, self)
    end

    ##
    # Returns the object itself as it is already a Pling::Device.
    #
    # @return [Pling::Device]
    def to_pling_device
      self
    end

  end
end
