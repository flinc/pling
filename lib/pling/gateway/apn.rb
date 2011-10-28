require 'socket'
require 'openssl'
require 'json'

module Pling
  module Gateway
    ##
    # Pling gateway to communicate with Apple's Push Notification service.
    #
    # This gateway handles these device types: 
    #     :apple, :apn, :ios, :ipad, :iphone, :ipod
    #
    # Configure it by providing the path to your certificate:
    #
    #     Pling::Gateway::APN.new({
    #       :certificate => '/path/to/certificate.pem', # Required
    #       :host => 'gateway.sandbox.push.apple.com'   # Optional
    #     })
    #
    class APN < Base
      handles :apple, :apn, :ios, :ipad, :iphone, :ipod

      ##
      # Initializes a new gateway to Apple's Push Notification service
      #
      # @param [Hash] configuration
      # @option configuration [#to_s] :certificate Path to PEM certificate file (Required)
      # @option configuration [String] :host Host to connect to (Default: gateway.push.apple.com)
      # @option configuration [Integer] :port Port to connect to (Default: 2195)
      def initialize(configuration)
        setup_configuration(configuration, :require => [:certificate])
      end

      protected

        ##
        # Sends the given message to the given device.
        #
        # @param [#to_pling_message] message
        # @param [#to_pling_device] device
        def deliver!(message, device)
          token = [device.identifier].pack('H*')

          data = {
            :aps => {
              :alert => message.body,
              :badge => 0,
              :sound => :default
            }
          }.to_json

          connection.write([0, 0, 32, token, 0, data.size, data].pack('ccca*cca*'))
        end

      private

        def default_configuration
          super.merge({
            :host => 'gateway.push.apple.com',
            :port => 2195
          })
        end

        def connection
          @connection ||= OpenSSL::SSL::SSLSocket.new(tcp_socket, ssl_context).tap do |socket|
            socket.sync = true
            socket.connect
          end
        end

        def ssl_context
          @ssl_context ||= OpenSSL::SSL::SSLContext.new.tap do |context|
            certificate  = File.read(configuration[:certificate])

            context.cert = OpenSSL::X509::Certificate.new(certificate)
            context.key  = OpenSSL::PKey::RSA.new(certificate)
          end
        end

        def tcp_socket
          @tcp_socket ||= TCPSocket.new(configuration[:host], configuration[:port])
        end
    end
  end
end
