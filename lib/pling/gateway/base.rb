module Pling
  module Gateway
    class Base

      def handles?(device)
        self.class.handled_types.include?(device.type)
      end

      class << self
        def handles(*types)
          @handled_types = [types].flatten.map { |t| t.to_sym }
        end

        def handled_types
          @handled_types ||= []
        end
      end

      protected

        def configuration
          @configuration ||= default_configuration
        end

        def default_configuration
          {}
        end

        def setup_configuration(config = {}, opts = {})
          config.each_pair do |key, value|
            configuration[key.to_sym] = value
          end

          require_configuration(opts[:require] || [])
        end

      private

        def require_configuration(keys, message = nil)
          [keys].flatten.each do |key|
            raise(ArgumentError, message || "Option :#{key} is missing") unless configuration.key?(key.to_sym)
          end
        end
    end
  end
end
