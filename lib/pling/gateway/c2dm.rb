module Pling
  module Gateway
    class C2DM < Pling::Gateway::Base

      def initialize(configuration)
        setup_configuration(configuration, :require => [:email, :password, :source])
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