# Pling [![Travis build status of pling](http://travis-ci.org/flinc/pling.png)](http://travis-ci.org/flinc/pling)

Pling is a notification framework that supports multiple gateways. This gem implements the basic framework as well as a gateway to Google's Cloud to Device Messaging Service (C2DM) and Apple's Push Notification Service (APN).


## Requirements

This gem has two runtime dependencies

- faraday ~> 0.7
- json ~> 1.4

On JRuby it also requires the jruby-openssl gem.


## Install

Add this line to your `Gemfile`:

    gem 'pling'

## Configuration

The configuration is pretty simple. Just add a configuration block like this to your code:

    Pling.configure do |config|
      config.gateways.use Pling::C2DM::Gateway, :email => 'your-email@gmail.com', :password => 'your-password', :source => 'your-app-name'
      config.gateways.use Pling::APN::Gateway, :certificate => '/path/to/certificate.pem'

      # config.middleware.use Your::Custom::Middleware, :your => :custom, :configuration => true

      # config.adapter = Your::Custom::Adapter.new
    end

## Usage

After configuring Pling you can send messages to devices by like this:

    message = Pling::Message.new("Hello from pling!")
    device  = Pling::Device.new(:identifier => 'XXXXXXXXXX...XXXXXX', :type => :iphone)
    device.deliver(message)

    # ... or call Pling.delver
    Pling.deliver(message, device)

Pling has three core components:

* A _device_ describes a concrete receiver such as a smartphone or an email address. 
* A _message_ wraps the content delivered to a device. 
* A _gateway_ handles the communication with the service provider used to deliver the message.

You can easily integrate pling into your existing application by implementing `#to_pling_device` on your device models and `#to_pling_message` on your message models. Use these methods to either convert your models into `Pling::Device` and `Pling::Message` objects or return `self` and make sure your models implement the basic `Pling::Device` and `Pling::Message` interfaces.

### Devices

Devices store an identifier and a type.

  Example:

    email_device  = Pling::Device.new(:identifier => 'someone@example.com', :type => :email)
    iphone_device = Pling::Device.new(:identifier => 'XXXXXXXXXX...XXXXXX', :type => :iphone)


### Messages

The `Message` stores the content as well as additional options that may be evaluated by the gateways.

  Example:

    options = {} # To be added
    message = Pling::Message.new("Hello from Pling", options)


### Gateways

The Gateway delivers the message in the required format to the service provider.

Currently there are these gateways available:

* [Android C2DM](http://rdoc.info/github/flinc/pling/master/Pling/Gateway/C2DM)
* [Apple Push Notification](http://rdoc.info/github/flinc/pling/master/Pling/Gateway/APN)
* [SMS via Mobilant](https://github.com/flinc/pling-mobilant) (See `pling-mobilant` gem)
* [Email](https://github.com/flinc/pling-actionmailer) (See `pling-actionmailer` gem)

See the [API documentation](http://rdoc.info/github/flinc/pling) for details on the available gateways.


### Middleware

Pling has support for middlewares. Currently pling itself does not provide any middlewares but you can easily implement your own. All you need is a class that responds to `#deliver(message, device)` which yields to call the next middleware on the stack. You might just want to subclass `Pling::Middleware::Base` to get a simple configuration management. 

    class Pling::Middleware::TimeFilter < Pling::Middleware::Base
      def deliver(message, device)
        yield(message, device) if configuration[:range].include? Time.now.hour
      end

      protected

        def default_configuration
          super.merge({
            :range => 8..22
          })
        end
    end

You can either add middlewares for all gateways or for specific gateways:

    Pling.configure do |config|
      config.gateways.use Pling::APN::Gateway, {
        :certificate => '/path/to/certificate.pem',
        :middlewares => [
          [Pling::Middleware::TimeFilter, { :range => 9..17 }] # Don't deliver any messages to iOS devices between 9am and 5pm
        ]
      }

      # Don't deliver any messages between 8am and 10pm
      config.middleware.use Pling::Middleware::TimeFilter
    end


### Adapters

Pling supports different adapters. A adapter is in a way similar to a middleware but is responsible for dispatching a device and a message to a gateway.
The default adapter simply looks up the first matching gateway for the given device and calls its `#deliver(message, device)` method. Adapters are handy
when you want to add support for background queues. Have a look at [this example](https://gist.github.com/1308846) of an adapter for Resque.


## Build Status

Pling is on [Travis](http://travis-ci.org/flinc/pling) running the specs on Ruby 1.8.7, Ruby Enterprise Edition, Ruby 1.9.2, Ruby HEAD, JRuby, Rubinius and Rubinius 2.


## Known issues

See [the issue tracker on GitHub](https://github.com/flinc/pling/issues).


## Repository

See [the repository on GitHub](https://github.com/flinc/pling) and feel free to fork it!


## Contributors

See a list of all contributors on [GitHub](https://github.com/flinc/pling/contributors). Thanks a lot everyone!


## Copyright

Copyright (c) 2010-2011 [flinc AG](https://flinc.org/). See LICENSE for details.