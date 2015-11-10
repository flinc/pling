require 'spec_helper'

describe Pling::C2DM::Gateway do

  let(:valid_configuration) do
    { :email => 'someone@gmail.com', :password => 'random', :source => 'some-source' }
  end

  let(:authentication_response_double) do
    double(:authentication_response_double, :success? => true, :status => 200, :body => "SID=SOMESID\nAuth=S0ME-ToKeN123")
  end

  let(:push_response_double) do
    double(:push_response_double, :success? => true, :status => 200, :body => "")
  end

  let(:connection_double) do
    double(:connection_double).tap do |connection|
      connection.stub(:post).
        with('https://www.google.com/accounts/ClientLogin', anything).
        and_return(authentication_response_double)

      connection.stub(:post).
        with('https://android.apis.google.com/c2dm/send', anything, anything).
        and_return(push_response_double)
    end
  end

  before { Faraday.stub(:new).and_return(connection_double) }

  it 'should handle various apn related device types' do
    Pling::C2DM::Gateway.handled_types.should =~ [:android, :c2dm]
  end

  context 'when created with an invalid configuration' do
    [:email, :password, :source].each do |attribute|
      it "should raise an error when :#{attribute} is missing" do
        configuration = valid_configuration
        configuration.delete(attribute)
        expect { Pling::C2DM::Gateway.new(configuration) }.to raise_error(ArgumentError, /:#{attribute} is missing/)
      end
    end
  end

  context 'when created with valid configuration' do

    context 'authenticating' do
      let(:valid_authentication_params) do
        {
          :accountType => 'HOSTED_OR_GOOGLE',
          :service => 'ac2dm',
          :Email => valid_configuration[:email],
          :Passwd => valid_configuration[:password],
          :source => valid_configuration[:source]
        }
      end

      it 'should not raise an error' do
        expect { Pling::C2DM::Gateway.new(valid_configuration) }.to_not raise_error
      end

      it 'should try to authenticate' do
        connection_double.should_receive(:post).
          with('https://www.google.com/accounts/ClientLogin', valid_authentication_params).
          and_return(authentication_response_double)

        Pling::C2DM::Gateway.new(valid_configuration)
      end

      it 'should extract the token from the response body' do
        gateway = Pling::C2DM::Gateway.new(valid_configuration)
        gateway.token.should eq('S0ME-ToKeN123')
      end

      it 'should raise an error if authentication was not successful' do
        authentication_response_double.stub(:status => 403, :success? => false, :body => 'Error=BadAuthentication')

        expect { Pling::C2DM::Gateway.new(valid_configuration) }.to raise_error(Pling::AuthenticationFailed, /Authentication failed: \[403\] Error=BadAuthentication/)
      end

      it 'should raise an error if it could not extract a token from the response' do
        authentication_response_double.stub(:body).and_return('SOMERANDOMBODY')

        expect { Pling::C2DM::Gateway.new(valid_configuration) }.to raise_error(Pling::AuthenticationFailed, /Token extraction failed/)
      end
    end

    context 'configuration' do
      it 'should allow configuring Faraday\'s :connection settings' do
        Faraday.should_receive(:new).with(:ssl => { :verify => false })
        Pling::C2DM::Gateway.new(valid_configuration.merge(:connection => { :ssl => { :verify => false }}))
      end

      it 'should use Faraday::Response::Logger when :debug is set to true' do
        builder = double(:builder_double, :use => true, :adapter => true)
        builder.should_receive(:use).with(Faraday::Response::Logger)
        Faraday.stub(:new).and_yield(builder).and_return(connection_double)

        Pling::C2DM::Gateway.new(valid_configuration.merge(:debug => true))
      end

      it 'should use the adapter set with :adapter' do
        builder = double(:builder_double, :use => true, :adapter => true)
        builder.should_receive(:adapter).with(:typheus)
        Faraday.stub(:new).and_yield(builder).and_return(connection_double)

        Pling::C2DM::Gateway.new(valid_configuration.merge(:adapter => :typheus))
      end

      it 'should allow configuring the authentication_url' do
        connection_double.should_receive(:post).
          with('http://example.com/authentication', anything).
          and_return(authentication_response_double)

        Pling::C2DM::Gateway.new(valid_configuration.merge(:authentication_url => 'http://example.com/authentication'))
      end
    end
  end

  describe '#deliver' do
    subject { Pling::C2DM::Gateway.new(valid_configuration) }

    let(:message) { Pling::Message.new('Hello from Pling') }
    let(:device)  { Pling::Device.new(:identifier => 'DEVICEIDENTIFIER', :type => :android) }

    let(:valid_push_params) do
      {
        :registration_id => device.identifier,
        :'data.body' => message.body,
        :collapse_key => message.body.hash
      }
    end

    let(:valid_push_headers) do
      {
        :Authorization => 'GoogleLogin auth=S0ME-ToKeN123'
      }
    end

    it 'should raise an error if no message is given' do
      expect { subject.deliver(nil, device) }.to raise_error
    end

    it 'should raise an error the device is given' do
      expect { subject.deliver(message, nil) }.to raise_error
    end

    it 'should call #to_pling_message on the given message' do
      message.should_receive(:to_pling_message).and_return(message)
      subject.deliver(message, device)
    end

    it 'should call #to_pling_device on the given device' do
      device.should_receive(:to_pling_device).and_return(device)
      subject.deliver(message, device)
    end

    it 'should try to deliver the given message' do
      connection_double.should_receive(:post).
        with('https://android.apis.google.com/c2dm/send', valid_push_params, valid_push_headers).
        and_return(push_response_double)

      subject.deliver(message, device)
    end

    it 'should raise a Pling::DeliveryFailed exception if the delivery was not successful' do
      connection_double.should_receive(:post).with('https://android.apis.google.com/c2dm/send', anything, anything).
        and_return(push_response_double)
      push_response_double.stub(:status => 401, :success? => false, :body => "Something went wrong")

      expect { subject.deliver(message, device) }.to raise_error Pling::DeliveryFailed, /Something went wrong/
    end

    it 'should raise a Pling::DeliveryFailed exception if the response body contained an error' do
      connection_double.should_receive(:post).with('https://android.apis.google.com/c2dm/send', anything, anything).
        and_return(push_response_double)
      push_response_double.stub(:status => 200, :success? => true, :body => "Error=SomeError")

      expect { subject.deliver(message, device) }.to raise_error Pling::DeliveryFailed, /Error=SomeError/
    end

    it 'should send data.badge if the given message has a badge' do
      connection_double.should_receive(:post).
        with(anything, hash_including(:'data.badge' => '10'), anything).
        and_return(push_response_double)
      message.badge = 10
      subject.deliver(message, device)
    end

    it 'should send data.sound if the given message has a sound' do
      connection_double.should_receive(:post).
        with(anything, hash_including(:'data.sound' => 'pling'), anything).
        and_return(push_response_double)
      message.sound = :pling
      subject.deliver(message, device)
    end

    it 'should send data.subject if the given message has a subject' do
      connection_double.should_receive(:post).
        with(anything, hash_including(:'data.subject' => 'Important!'), anything).
        and_return(push_response_double)
      message.subject = 'Important!'
      subject.deliver(message, device)
    end

    context 'when configured to include payload' do
      before do
        valid_configuration.merge!(:payload => true)
        message.payload = { :data => 'available' }
      end

      it 'should include the given payload' do
        connection_double.should_receive(:post).
          with(anything, hash_including(:'data.data' => 'available'), anything).
          and_return(push_response_double)
        subject.deliver(message, device)
      end
    end

    context 'when configured to not include payload' do
      before do
        valid_configuration.merge!(:payload => false)
        message.payload = { :data => 'available' }
      end

      it 'should include the given payload' do
        connection_double.should_receive(:post).
          with(anything, hash_not_including(:'data.data' => 'available'), anything).
          and_return(push_response_double)
        subject.deliver(message, device)
      end
    end

    [:QuotaExceeded, :DeviceQuotaExceeded,
     :InvalidRegistration, :NotRegistered,
     :MessageTooBig, :MissingCollapseKey].each do |exception|
      it "should raise a Pling::C2DM::#{exception} when the response body is ''" do
        push_response_double.stub(:body => "Error=#{exception}")
        expect { subject.deliver(message, device) }.to raise_error Pling::C2DM.const_get(exception)
      end
    end
  end
end     
