require 'faraday'
require 'faraday_middleware'
require 'json'

module Pling
  module GCM
    ##
    # Pling gateway to communicate with Google's Android GCM service.
    #
    # The gateway is implemented using Faraday. It defaults to Faraday's :net_http adapter.
    # You can customize the adapter by passing the :adapter configuration.
    #
    # @example
    #
    #   Pling::GCM::Gateway.new({
    #     :key                => 'your-api-key', # Your google account's api key (Required)
    #     :push_url           => 'http://...',   # The push url to use (Optional, Default: GCM default authentication url)
    #     :adapter            => :net_http,      # The Faraday adapter you want to use (Optional, Default: :net_http)
    #     :connection         => {}              # Options you want to pass to Faraday (Optional, Default: {})
    #   })
    class Gateway < Pling::Gateway

      handles :android, :gcm

      ##
      # Initializes a new gateway to Apple's Push Notification service
      #
      # @param [Hash] configuration
      # @option configuration [String] :key Your google account's api key (Required)
      # @option configuration [String] :push_url The URL to push to (Optional)
      # @option configuration [Symbol] :adapter The Faraday adapter to use (Optional)
      # @option configuration [String] :connection Any options for Faraday (Optional)
      # @raise Pling::AuthenticationFailed
      def initialize(configuration)
        super
        require_configuration([:key])
      end

      ##
      # Sends the given message to the given device.
      #
      # @param [#to_pling_message] message
      # @param [#to_pling_device] device
      # @raise Pling::DeliveryFailed
      def deliver!(message, device)
        data = {
          :registration_ids => [device.identifier],
          :data => {
            :body  => message.body,
            :badge => message.badge,
            :sound => message.sound,
            :subject => message.subject
          }.delete_if { |_, value| value.nil? },
          :collapse_key => "collapse-#{message.body.hash}"
        }

        data[:data].merge!(message.payload) if configuration[:payload] && message.payload

        response = connection.post(configuration[:push_url], data, { :Authorization => "key=#{configuration[:key]}"})

        if !response.success? || response.body['failure'].to_i > 0
          error_class = Pling::GCM.const_get(response.body['results'][0]['error']) rescue Pling::DeliveryFailed
          raise error_class.new("GCM Delivery failed: [#{response.status}] #{response.body}", message, device)
        end
      end

    private

     def default_configuration
        super.merge({
          :push_url           => 'https://android.googleapis.com/gcm/send',
          :adapter            => :net_http,
          :connection         => {}
        })
      end

      def connection
        @connection ||= Faraday.new(configuration[:connection]) do |builder|
          builder.use FaradayMiddleware::EncodeJson
          builder.use FaradayMiddleware::ParseJson, :content_type => /\bjson$/
          builder.use Faraday::Response::Logger if configuration[:debug]
          builder.adapter(configuration[:adapter])
        end
      end
    end
  end
end
