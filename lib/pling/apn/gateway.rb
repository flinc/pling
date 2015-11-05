require 'socket'
require 'openssl'
require 'json'
require 'connection_pool'

module Pling
  module APN
    ##
    # Pling gateway to communicate with Apple's Push Notification service.
    #
    # This gateway handles these device types:
    #     :apple, :apn, :ios, :ipad, :iphone, :ipod
    #
    # Configure it by providing the path to your certificate:
    #
    #     Pling::APN::Gateway.new({
    #       :certificate => '/path/to/certificate.pem', # Required
    #       :host => 'gateway.sandbox.push.apple.com'   # Optional
    #     })
    #
    class Gateway < Pling::Gateway
      handles :apple, :apn, :ios, :ipad, :iphone, :ipod

      ##
      # Initializes a new gateway to Apple's Push Notification service
      #
      # @param [Hash] configuration
      # @option configuration [#to_s] :certificate Path to PEM certificate file (Required)
      # @option configuration [String] :host Host to connect to (Default: gateway.push.apple.com)
      # @option configuration [Integer] :port Port to connect to (Default: 2195)
      def initialize(configuration)
        super
        require_configuration(:certificate)
        setup!
      end

      ##
      # Establishes a new connection if connection is not available or closed
      def setup!
        setup_connection_pool
      end

      ##
      # Sends the given message to the given device without using the middleware.
      #
      # @param [#to_pling_message] message
      # @param [#to_pling_device] device
      def deliver!(message, device)
        data = {
          :aps => {
            :alert => message.body,
            :badge => message.badge && message.badge.to_i,
            :sound => message.sound,
          }.delete_if { |_, value| value.nil? }
        }

        data[:aps]['content-available'] = 1 if message.content_available
        data.merge!(message.payload) if configuration[:payload] && message.payload

        data = data.to_json

        if data.bytesize > 2048
          raise Pling::DeliveryFailed.new(
            "Payload size of #{data.bytesize} exceeds allowed size of 2048 bytes.",
            message,
          device)
        end

        token = [device.identifier].pack('H*')

        connection.write([0, token.bytesize, token, data.bytesize, data].pack('cna*na*'))
      end

      private

        def default_configuration
          super.merge(
            :host => 'gateway.push.apple.com',
            :port => 2195,
            :payload => false,
            :pool_size => 3,
            :timeout => 5
          )
        end

        def connection
          @connection
        end

        def setup_connection_pool
          @connection ||= connection_pool
        end

        def new_connection
          Connection.new(
            :host        => configuration[:host],
            :port        => configuration[:port],
            :certificate => configuration[:certificate]
          )
        end

        def connection_pool
          ConnectionPool::Wrapper.new(size: configuration[:pool_size], timeout: configuration[:timeout]) do
            new_connection
          end
        end
    end
  end
end
