module Pling
  module Middleware
    ##
    # This is the base class to implement custom middleware for pling.
    #
    # Middleware should inherit from this base class and implement a {#deliver} method.
    # To call the next middleware on the stack this method must yield passing the given
    # message and device.
    #
    # @example
    #
    #     class Pling::Middleware::TimeFilter < Pling::Middleware::Base
    #       def deliver(message, device)
    #         yield(message, device) if configuration[:range].include? Time.now.hour
    #       end
    #     
    #       protected
    #     
    #         def default_configuration
    #           super.merge({
    #             :range => 8..22
    #           })
    #         end
    #     end
    class Base
      include Pling::Configurable

      ##
      # Initializes a new middleware instance
      #
      # @param [Hash] configuration
      def initialize(configuration = {})
        setup_configuration(configuration)
      end

      ##
      # Processes the given message and device and passes it to the next
      # middleware on the stack.
      #
      # @yield [message, device] Call the next middleware on the stack
      def deliver(message, device)
        yield(message, device)
      end
    end
  end
end