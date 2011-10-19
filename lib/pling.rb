require "pling/version"

module Pling

  autoload :Device,  'pling/device'
  autoload :Message, 'pling/message'
  autoload :Gateway, 'pling/gateway'

  @gateways = []

  class Error < StandardError
  end

  class AuthenticationFailed < Error
  end

  class DeliveryFailed < Error
  end

  class << self
    ##
    # Stores the list of available gateway instances
    #
    # @return [Array] list of available gateways
    attr_accessor :gateways

    def configure
      raise ArgumentError, 'No block given for Pling.configure' unless block_given?
      yield self
    end
  end

end
