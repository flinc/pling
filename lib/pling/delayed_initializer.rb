module Pling
  class DelayedInitializer < Array
    def use(*args)
      self << args
    end

    def initialize!
      map! do |item|
        item = item.kind_of?(Array) ? item.shift.new(*item) : item
        item.setup! if item.respond_to?(:setup!)
        item
      end
    end 
  end
end