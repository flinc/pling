module Pling
  
  ##
  # The {APN} module wraps Apple's Push Notification Service into an easy
  # to use API. You can use instances of {Gateway} to send push notifications
  # and instances of {Feedback} to get device identifiers that have been
  # marked invalid.
  module APN
    autoload :Connection, 'pling/apn/connection'
    autoload :Gateway, 'pling/apn/gateway'
    autoload :Feedback, 'pling/apn/feedback'
  end
end