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
    # The message subject - not supported by all gateways
    #
    # @overload subject
    # @overload subject=(subject)
    #   @param [#to_s] subject
    attr_reader :subject
    
    def subject=(subject)
      subject &&= subject.to_s
      @subject = subject
    end
    
    ##
    # The message badge - not supported by all gateways
    #
    # @overload badge
    # @overload badge=(badge)
    #   @param [#to_s] badge
    attr_reader :badge
    
    def badge=(badge)
      badge &&= badge.to_s
      @badge = badge
    end
    
    ##
    # The message sound - not supported by all gateways
    #
    # @overload sound
    # @overload sound=(sound)
    #   @param [#to_s] sound
    attr_reader :sound
    
    def sound=(sound)
      sound &&= sound.to_s
      @sound = sound
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
