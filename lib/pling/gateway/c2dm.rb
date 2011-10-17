module Pling
  module Gateway
    class C2DM < Pling::Gateway::Base

      def initialize(options)
        @options = {}
        [:username, :password, :source].each do |key|
          @options[key] = options[key] || options[key.to_s] or raise ArgumentError, "#{key} is missing"
        end
      end

      def deliver(message, device)
        raise "The given object #{message.inspect} does not implement #to_pling_message" unless message.respond_to?(:to_pling_message)
        raise "The given object #{device.inspect} does not implement #to_pling_device"   unless device.respond_to?(:to_pling_device)
        message = message.to_pling_message
        device  = device.to_pling_device
      end

    end
  end
end