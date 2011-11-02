require 'openssl'

module Pling
  module APN
    class Connection
      include Pling::Configurable

      def initialize(config)
        setup_configuration(config, :require => [:certificate])
        open
      end

      def open
        @ssl_socket ||= OpenSSL::SSL::SSLSocket.new(tcp_socket, ssl_context).tap do |socket|
          socket.sync = true
          socket.connect
        end

        self
      end

      def open?
        not closed?
      end

      def close
        if open?
          @ssl_socket.close
          @ssl_socket = nil
          @tcp_socket = nil
        end

        self
      end

      def closed?
        !@ssl_socket or @ssl_socket.closed?
      end

      def write(*args, &block)
        raise IOError, "Connection closed" if closed?
        @ssl_socket.write(*args, &block)
      end
      
      def puts(*args, &block)
        raise IOError, "Connection closed" if closed?
        @ssl_socket.write(*args, &block)
      end

      def read(*args, &block)
        @ssl_socket.read(*args, &block)
      end
      
      def gets(*args, &block)
        @ssl_socket.gets(*args, &block)
      end

      protected

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

      private

        def default_configuration
          super.merge(
            :host => 'gateway.push.apple.com',
            :port => 2195
          )
        end

    end
  end
end
