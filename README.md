# Pling [![Travis build status of pling](http://travis-ci.org/flinc/pling.png)](http://travis-ci.org/flinc/pling)

Pling is a notification framework that supports multiple gateways.


## Requirements



## Install

Add this line to your `Gemfile`:

    gem 'pling'

## Configuration

    Pling.configure do |config|
      config.gateways = [
        Pling::Gateway::C2DM.new(:email => 'your-email@gmail.com', :password => 'your-password', :source => 'your-app-name'),
        Pling::Gateway::Iphone.new(:options => 'here'),
        Pling::Gatewas::Email.new(:options => 'here')
      ]
    end

## Usage

Pling has three core components:

* A `Device` describes a concrete receiver such as a smartphone or an email address. 
* A `Message` wraps the content delivered to a device. 
* A `Gateway` handles the communication with the service provider used to deliver the message.

To integrate Pling in your application you have to implement a `to_pling` method on each of your models to convert your data into Pling compatible objects.

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

* Android C2DM (not yet implemented)
* iPhone Push (not yet implemented)
* SMS via Mobilant (See `pling-mobilant` gem, not yet implemented)
* E-Mail (See `pling-actionmailer` gem, not yet implemented)

#### Android C2DM

The Android C2DM gateway allows pushing of messages to android handsets using Google's C2DM service.

  Example:

    Pling::Gateway::C2DM.new({
      :email    => 'your-email@gmail.com', # Your google account's email address (Required)
      :password => 'your-password',        # Your google account's password (Required)
      :source   => 'your-app-name',        # Your applications source identifier (Required)

      :authentication_url => 'http://...', # The authentication url to use (Optional, Default: C2DM default authentication url)
      :push_url           => 'http://...', # The push url to use (Optional, Default: C2DM default authentication url)
      :adapter            => :net_http,    # The Faraday adapter you want to use (Optional, Default: :net_http)
      :connection         => {}            # Options you want to pass to Faraday (Optional, Default: {})
    })

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