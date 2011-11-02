module Pling
  ##
  # This module adds support for Google's Cloud to Device Messaging (C2DM) to pling.
  # Please refer to {Pling::C2DM::Gateway} for documentation.
  #
  # @see Pling::C2DM::Gateway
  module C2DM
    autoload :Gateway, 'pling/c2dm/gateway'

    class QuotaExceeded       < Pling::DeliveryFailed; end
    class DeviceQuotaExceeded < Pling::DeliveryFailed; end
    class InvalidRegistration < Pling::DeliveryFailed; end
    class NotRegistered       < Pling::DeliveryFailed; end
    class MessageTooBig       < Pling::DeliveryFailed; end
    class MissingCollapseKey  < Pling::DeliveryFailed; end
  end
end