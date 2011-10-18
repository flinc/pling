module Pling
  module Gateway
    class Base

      protected

        def options
          @options ||= default_options
        end

        def default_options
          {}
        end

        def setup_options(opts = {})
          opts.each_pair do |key, value|
            options[key.to_sym] = value
          end
        end

        def require_options(keys, message = nil)
          [keys].flatten.each do |key|
            raise(ArgumentError, message || "Option #{key} is missing") unless options.key?(key.to_sym)
          end
        end
        alias :require_option :require_options
    end
  end
end