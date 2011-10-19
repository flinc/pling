require "pling/version"

module Pling

  autoload :Device,  'pling/device'
  autoload :Message, 'pling/message'
  autoload :Gateway, 'pling/gateway'

  @gateways = []

  class Error < StandardError; end
  class AuthenticationFailed < Error; end
  class DeliveryFailed < Error; end
  class NoGatewayFound < Error; end

  class << self
    ##
    # Stores the list of available gateway instances
    #
    # @return [Array] list of available gateways
    attr_accessor :gateways


    ##
    # Allows configuration of Pling by passing a config object to the given block
    #
    # @yield [config]
    # @raise [ArgumentError] Raised when no block is given
    def configure
      raise ArgumentError, 'No block given for Pling.configure' unless block_given?
      yield self
    end


    ##
    # [INTERNAL METHOD] Converts the given object to the given pling type
    #
    # @private
    # @param object [Object] The object that needs to be converted
    # @param type [Symbol, String] #to_pling_ method suffix
    # @raise [ArgumentError] The object does not implement a #to_pling_ + type method
    def _convert(object, type)
      method = :"to_pling_#{type}"
      raise ArgumentError, "Instances of #{object.class} do not implement ##{method}" unless object.respond_to?(method)
      object && object.send(method)
    end
  end

end
