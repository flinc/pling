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
        ssl_socket.sync = true
        ssl_socket.connect

        self
      end

      def open?
        not closed?
      end

      def close
        ssl_socket.close rescue true
        tcp_socket.close rescue true

        self
      end

      def closed?
        ssl_socket.closed?
      end

      def write(*args, &block)
        raise IOError, "Connection closed" if closed?
        with_retries do
          ssl_socket.write(*args, &block)
        end
      end
      
      def puts(*args, &block)
        raise IOError, "Connection closed" if closed?
        with_retries do
          ssl_socket.puts(*args, &block)
        end
      end

      def read(*args, &block)
        raise IOError, "Connection closed" if closed?
        with_retries do
          ssl_socket.read(*args, &block)
        end
      end
      
      def gets(*args, &block)
        raise IOError, "Connection closed" if closed?
        with_retries do
          ssl_socket.gets(*args, &block)
        end
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

        def ssl_socket
          @ssl_socket ||= OpenSSL::SSL::SSLSocket.new(tcp_socket, ssl_context)
        end

      private

        def default_configuration
          super.merge(
            :host => 'gateway.push.apple.com',
            :port => 2195
          )
        end

        def with_retries(count = 3)
          yield
        rescue OpenSSL::SSL::SSLError, Errno::EPIPE, Errno::ENETDOWN
          if (count -= 1) > 0
            close; open; retry
          else
            raise IOError, $!.message
          end
        end
    end
  end
end
