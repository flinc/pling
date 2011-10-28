module Pling
  class DelayedInitializer < Array
    def use(*args)
      self << args
    end

    def initialize!
      map! do |item|
        item.kind_of?(Array) ? item.shift.new(*item) : item
      end
    end 
  end
end