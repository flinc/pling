require "pling/version"

module Pling

  @gateways = []

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
