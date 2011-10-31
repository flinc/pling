module Pling
  module APN
    class Feedback
      
      def get
        @feedback ||= fetch
      end
      
      private
      
        def fetch
          []
        end
      
    end
  end
end