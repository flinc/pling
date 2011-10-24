module Pling
  module Gateway
    class Base
      include Pling::Configurable

      class << self
        def handles(*types)
          @handled_types = [types].flatten.map { |t| t.to_sym }
        end

        def handled_types
          @handled_types ||= []
        end
      end

      def handles?(device)
        self.class.handled_types.include?(device.type)
      end
    end
  end
end
