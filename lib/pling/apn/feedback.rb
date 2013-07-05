module Pling
  module APN
    
    ##
    # Instances of this class can be used to retrieve device identifiers that
    # have been marked invalid. This should be done on a regular basis since
    # Apple will ban you if you continue to send push notifications to
    # invalid devices.
    #
    # The only operation supported by instances of this class is {#get}. 
    # The method simply returns a list of the identifieres that have been 
    # marked invalid since you last called this method.
    #
    # @example
    #
    #   feedback = Pling::APN::Feedback.new(:certificate => '/path/to/certificate.pem')
    #   tokens = feedback.get
    #
    #   tokens.each do |token|
    #     # process token
    #   end
    #
    class Feedback
      include Pling::Configurable
      
      ##
      # Creates a new instance of this class and establishes a connection to
      # Apple's Push Notification Service, retrieves a list of invalid device
      # identifiers and then closes the connection, since Apple closes it on
      # their side.
      # 
      # For testing purposes, you should use Apple's sandbox feedback service
      # +feedback.sandbox.push.apple.com+. In order to do this, you have to
      # specify the optional +:host+ parameter when creating instances of this
      # class.
      #
      # @param [Hash] configuration Parameters to control the connection configuration
      # @option configuration [#to_s] :certificate Path to PEM certificate file (Required)
      # @option configuration [String] :host Host to connect to (Default: feedback.push.apple.com)
      # @option configuration [Integer] :port Port to connect to (Default: 2196)
      #
      # @example
      #
      #   Pling::APN::Feedback.new(
      #     :certificate => '/path/to/certificate.pem',
      #     :host => 'feedback.push.apple.com',
      #     :port => 2196
      #   )
      #
      def initialize(configuration)
        setup_configuration(configuration, :require => :certificate)
      end
      
      ##
      # Retrieves all device identifiers that have been marked invalid since
      # the method has been called last.
      #
      # @return [Array<String>] The list of invalid device identifiers
      #
      def get
        tokens = []
        while line = connection.gets
          time, length = line.unpack("Nn")
          tokens << line.unpack("x6H#{length << 1}").first
        end
        connection.close
        tokens
      end

      private

        def connection
          @connection ||= Connection.new(
            :host        => configuration[:host],
            :port        => configuration[:port],
            :certificate => configuration[:certificate]
          )
        end

        def default_configuration
          super.merge(
            :host => 'feedback.push.apple.com',
            :port => 2196
          )
        end

    end
  end
end
