module Pling
  class Device

    attr_reader :identifier, :type

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
    # Sets the identifier to the given value.
    #
    # @param [#to_s] identifier
    def identifier=(identifier)
      identifier &&= identifier.to_s
      @identifier = identifier
    end

    ##
    # Sets the type to the given value.
    #
    # @param [#to_sym] type
    def type=(type)
      type &&= type.to_sym
      @type = type
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
      raise "The given object #{message.inspect} does not implement #to_pling_message" unless message.respond_to?(:to_pling_message)
      message &&= message.to_pling_message
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