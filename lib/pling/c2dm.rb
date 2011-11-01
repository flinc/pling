module Pling
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