require 'spec_helper'

describe Pling::GCM::Gateway do

  let(:valid_configuration) do
    { :key => 'some-key' }
  end

  let(:push_response_double) do
    double(:response_double, :success? => true, :status => 200, :body => "")
  end

  let(:connection_mock) do
    double(:connection_double).tap do |connection|
      connection.stub(:post).
        with('https://android.googleapis.com/gcm/send', anything, anything).
        and_return(push_response_double)
    end
  end

  let(:message) { Pling::Message.new('Hello from Pling') }
  let(:device)  { Pling::Device.new(:identifier => 'DEVICEIDENTIFIER', :type => :android) }


  before { Faraday.stub(:new).and_return(connection_mock) }

  it 'should handle various apn related device types' do
    Pling::GCM::Gateway.handled_types.should =~ [:android, :gcm]
  end

  context 'when created with an invalid configuration' do
    [:key].each do |attribute|
      it "should raise an error when :#{attribute} is missing" do
        configuration = valid_configuration
        configuration.delete(attribute)
        expect { Pling::GCM::Gateway.new(configuration) }.to raise_error(ArgumentError, /:#{attribute} is missing/)
      end
    end
  end

  context 'when created with valid configuration' do

    context 'configuration' do
      it 'should allow configuring Faraday\'s :connection settings' do
        Faraday.should_receive(:new).with(:ssl => { :verify => false })
        Pling::GCM::Gateway.new(valid_configuration.merge(:connection => { :ssl => { :verify => false }})).deliver(message, device)
      end

      it 'should use Faraday::Response::Logger when :debug is set to true' do
        builder = double(:builder_double, :use => true, :adapter => true)
        builder.should_receive(:use).with(Faraday::Response::Logger)
        Faraday.stub(:new).and_yield(builder).and_return(connection_mock)

        Pling::GCM::Gateway.new(valid_configuration.merge(:debug => true)).deliver(message, device)
      end

      it 'should use the adapter set with :adapter' do
        builder = double(:builder_double, :use => true, :adapter => true)
        builder.should_receive(:adapter).with(:typheus)
        Faraday.stub(:new).and_yield(builder).and_return(connection_mock)

        Pling::GCM::Gateway.new(valid_configuration.merge(:adapter => :typheus)).deliver(message, device)
      end

    end
  end

  describe '#deliver' do
    subject { Pling::GCM::Gateway.new(valid_configuration) }

    let(:valid_push_params) do
      {
        :registration_ids => [device.identifier],
        :data => { :body => message.body },
        :collapse_key => "collapse-#{message.body.hash}"
      }
    end

    let(:valid_push_headers) do
      {
        :Authorization => 'key=some-key'
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
        with('https://android.googleapis.com/gcm/send', valid_push_params, valid_push_headers).
        and_return(push_response_double)

      subject.deliver(message, device)
    end

    it 'should raise a Pling::DeliveryFailed exception if the delivery was not successful' do
      connection_mock.should_receive(:post).and_return(push_response_double)
      push_response_double.stub(:status => 401, :success? => false, :body => "Something went wrong")

      expect { subject.deliver(message, device) }.to raise_error Pling::DeliveryFailed, /Something went wrong/
    end

    it 'should raise a Pling::DeliveryFailed exception if the response body contained an error' do
      connection_mock.should_receive(:post).and_return(push_response_double)
      push_response_double.stub(:status => 200, :success? => true, :body => { 'failure' => 1, 'results' => ['error' => 'SomeError'] })

      expect { subject.deliver(message, device) }.to raise_error Pling::DeliveryFailed, /SomeError/
    end

    it 'should send data.badge if the given message has a badge' do
      connection_mock.should_receive(:post).
        with(anything, hash_including(:data => hash_including({ :badge => '10' })), anything).
        and_return(push_response_double)
      message.badge = 10
      subject.deliver(message, device)
    end

    it 'should send data.sound if the given message has a sound' do
      connection_mock.should_receive(:post).
        with(anything, hash_including(:data => hash_including({ :sound => 'pling' })), anything).
        and_return(push_response_double)
      message.sound = :pling
      subject.deliver(message, device)
    end

    it 'should send data.subject if the given message has a subject' do
      connection_mock.should_receive(:post).
        with(anything, hash_including(:data => hash_including({ :subject => 'Important!' })), anything).
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
        connection_mock.should_receive(:post).
          with(anything, hash_including(:data => hash_including({ :data => 'available' })), anything).
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
        connection_mock.should_receive(:post).
          with(anything, hash_not_including(:'data.data' => 'available'), anything).
          and_return(push_response_double)
        subject.deliver(message, device)
      end
    end

    [:MissingRegistration, :InvalidRegistration, :MismatchSenderId,
     :NotRegistered, :MessageTooBig, :InvalidTtl, :Unavailable,
     :InternalServerError].each do |exception|
      it "should raise a Pling::GCM::#{exception} when the response body is ''" do
        push_response_double.stub(:body => { 'failure' => 1, 'results' => [{ 'error' => exception }]})
        expect { subject.deliver(message, device) }.to raise_error Pling::GCM.const_get(exception)
      end
    end
  end
end     
