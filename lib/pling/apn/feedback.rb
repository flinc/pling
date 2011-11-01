module Pling
  module APN
    class Feedback
      include Pling::Configurable

      def initialize(config)
        setup_configuration(config, :require => :certificate)
      end

      def get
        tokens = []
        while line = connection.gets
          time, length = line.unpack("Nn")
          tokens << line.unpack("x6H#{length << 1}").first
        end
        tokens
      end

      private

        def connection
          @connection ||= Connection.new(
            :host        => configuration[:host],
            :port        => configuration[:port],
            :certificate => configuration[:certificate]
          )
        end

        def default_configuration
          super.merge(
            :host => 'feedback.push.apple.com',
            :port => 2196
          )
        end

    end
  end
end
