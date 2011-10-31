require 'spec_helper'

describe Pling::C2DM::Gateway do

  let(:valid_configuration) do
    { :email => 'someone@gmail.com', :password => 'random', :source => 'some-source' }
  end

  let(:authentication_response_mock) do
    mock('Faraday authentication response', :success? => true, :status => 200, :body => "SID=SOMESID\nAuth=S0ME-ToKeN123")
  end

  let(:push_response_mock) do
    mock('Faraday send response', :success? => true, :status => 200, :body => "")
  end

  let(:connection_mock) do
    mock('Faraday connection').tap do |mock|
      mock.stub(:post).
        with('https://www.google.com/accounts/ClientLogin', anything).
        and_return(authentication_response_mock)

      mock.stub(:post).
        with('https://android.apis.google.com/c2dm/send', anything, anything).
        and_return(push_response_mock)
    end
  end

  before { Faraday.stub(:new).and_return(connection_mock) }

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
        connection_mock.should_receive(:post).
          with('https://www.google.com/accounts/ClientLogin', valid_authentication_params).
          and_return(authentication_response_mock)

        Pling::C2DM::Gateway.new(valid_configuration)
      end

      it 'should extract the token from the response body' do
        gateway = Pling::C2DM::Gateway.new(valid_configuration)
        gateway.token.should eq('S0ME-ToKeN123')
      end

      it 'should raise an error if authentication was not successful' do
        authentication_response_mock.stub(:status => 403, :success? => false, :body => 'Error=BadAuthentication')

        expect { Pling::C2DM::Gateway.new(valid_configuration) }.to raise_error(Pling::AuthenticationFailed, /Authentication failed: \[403\] Error=BadAuthentication/)
      end

      it 'should raise an error if it could not extract a token from the response' do
        authentication_response_mock.stub(:body).and_return('SOMERANDOMBODY')

        expect { Pling::C2DM::Gateway.new(valid_configuration) }.to raise_error(Pling::AuthenticationFailed, /Token extraction failed/)
      end
    end

    context 'configuration' do
      it 'should allow configuring Faraday\'s :connection settings' do
        Faraday.should_receive(:new).with(:ssl => { :verify => false })
        Pling::C2DM::Gateway.new(valid_configuration.merge(:connection => { :ssl => { :verify => false }}))
      end

      it 'should use Faraday::Response::Logger when :debug is set to true' do
        builder = mock(:use => true, :adapter => true)
        builder.should_receive(:use).with(Faraday::Response::Logger)
        Faraday.stub(:new).and_yield(builder).and_return(connection_mock)

        Pling::C2DM::Gateway.new(valid_configuration.merge(:debug => true))
      end

      it 'should use the adapter set with :adapter' do
        builder = mock(:use => true, :adapter => true)
        builder.should_receive(:adapter).with(:typheus)
        Faraday.stub(:new).and_yield(builder).and_return(connection_mock)

        Pling::C2DM::Gateway.new(valid_configuration.merge(:adapter => :typheus))
      end

      it 'should allow configuring the authentication_url' do
        connection_mock.should_receive(:post).
          with('http://example.com/authentication', anything).
          and_return(authentication_response_mock)

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
      connection_mock.should_receive(:post).
        with('https://android.apis.google.com/c2dm/send', valid_push_params, valid_push_headers).
        and_return(push_response_mock)

      subject.deliver(message, device)
    end

    it 'should raise a Pling::DeliveryFailed exception if the delivery was not successful' do
      connection_mock.should_receive(:post).
        with('https://android.apis.google.com/c2dm/send', valid_push_params, valid_push_headers).
        and_return(push_response_mock)

      push_response_mock.stub(:status => 401, :success? => false, :body => "Something went wrong")

      expect { subject.deliver(message, device) }.to raise_error Pling::DeliveryFailed, /Something went wrong/
    end

    it 'should raise a Pling::DeliveryFailed exception if the response body contained an error' do
      connection_mock.should_receive(:post).
        with('https://android.apis.google.com/c2dm/send', valid_push_params, valid_push_headers).
        and_return(push_response_mock)

      push_response_mock.stub(:status => 200, :success? => true, :body => "Error=SomeError")

      expect { subject.deliver(message, device) }.to raise_error Pling::DeliveryFailed, /Error=SomeError/
    end
  end
end
