module Pling
  class Message
    ##
    # The message content
    #
    # @overload content
    # @overload content=(content)
    #   @param [#to_s] content
    attr_reader :content

    def content=(content)
      content &&= content.to_s
      @content = content
    end

    ##
    # Creates a new Pling::Message instance with the given content
    #
    # @overload initialize(content)
    #   @param [#to_s] content
    # @overload initialize(attributes)
    #   @param [Hash] attributes
    #   @option attributes [#to_s] :content
    def initialize(*args)
      attributes = case param = args.shift
        when String
          (args.last || {}).merge(:content => param)
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
    # A message is valid if it has a content.
    #
    # @return [Boolean]
    def valid?
      !!content
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