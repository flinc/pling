module Pling
  ##
  # This module adds support for Google Cloud Messaging for Android (GCM) to pling.
  # Please refer to {Pling::GCM::Gateway} for documentation.
  #
  # @see Pling::GCM::Gateway
  module GCM
    autoload :Gateway, 'pling/gcm/gateway'

    class MissingRegistration < Pling::DeliveryFailed; end
    class InvalidRegistration < Pling::DeliveryFailed; end
    class MismatchSenderId    < Pling::DeliveryFailed; end
    class NotRegistered       < Pling::DeliveryFailed; end
    class MessageTooBig       < Pling::DeliveryFailed; end
    class InvalidTtl          < Pling::DeliveryFailed; end
    class Unavailable         < Pling::DeliveryFailed; end
    class InternalServerError < Pling::DeliveryFailed; end
  end
end


