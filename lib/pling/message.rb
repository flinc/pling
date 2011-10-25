module Pling
  class Message
    ##
    # The message body
    #
    # @overload body
    # @overload body=(body)
    #   @param [#to_s] body
    attr_reader :body

    def body=(body)
      body &&= body.to_s
      @body = body
    end

    ##
    # Creates a new Pling::Message instance with the given body
    #
    # @overload initialize(body)
    #   @param [#to_s] body
    # @overload initialize(attributes)
    #   @param [Hash] attributes
    #   @option attributes [#to_s] :body
    def initialize(*args)
      attributes = case param = args.shift
        when String
          (args.last || {}).merge(:body => param)
        when Hash
          param
        else
          {}
      end

      attributes.each_pair do |key, value|
        method = "#{key}="
        send(method, value) if respond_to?(method)
      end
    end

    ##
    # A message is valid if it has a body.
    #
    # @return [Boolean]
    def valid?
      !!body
    end

    ##
    # Returns the object itself as it is already a Pling::Message.
    #
    # @return [Pling::Message]
    def to_pling_message
      self
    end
  end
end
