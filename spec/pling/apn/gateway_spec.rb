require 'spec_helper'

describe Pling::APN::Gateway do

  let(:valid_configuration) { { :certificate => '/path/to/certificate.pem' } }

  let(:message) { Pling::Message.new('Hello from Pling') }

  let(:device)  { Pling::Device.new(:identifier => '0' * 64, :type => :iphone) }

  let(:connection) { double(Pling::APN::Connection).as_null_object }

  before do
    Pling::APN::Connection.stub(:new).and_return(connection)
  end

  it 'should handle various apn related device types' do
    Pling::APN::Gateway.handled_types.should =~ [:apple, :apn, :ios, :ipad, :iphone, :ipod]
  end

  describe '#setup!' do
    before do
      valid_configuration.merge!(pool_size: 99, timeout: 55)
    end

    subject { Pling::APN::Gateway.new(valid_configuration) }

    let(:connection_pool) { double(:connection_pool_double) }

    it 'initializes a new connection pool for the APN connection' do
      ConnectionPool::Wrapper.should_receive(:new).with(size: 99, timeout: 55).and_return(connection_pool)
      subject.setup!
    end
  end

  describe '#deliver' do
    subject { Pling::APN::Gateway.new(valid_configuration) }

    it 'should raise an error if no message is given' do
      expect { subject.deliver(nil, device) }.to raise_error
    end

    it 'should raise an error the device is given' do
      expect { subject.deliver(message, nil) }.to raise_error
    end

    it 'should initialize a new APN connection if none is established' do
      Pling::APN::Connection.should_receive(:new).and_return(connection)
      subject.deliver(message, device)

      Pling::APN::Connection.should_not_receive(:new)
      subject.deliver(message, device)
    end

    it 'should call #to_pling_message on the given message' do
      message.should_receive(:to_pling_message).and_return(message)
      subject.deliver(message, device)
    end

    it 'should call #to_pling_device on the given device' do
      device.should_receive(:to_pling_device).and_return(device)
      subject.deliver(message, device)
    end

    it 'should raise an exception when the payload exceeds 2048 bytes' do
      message.body = "X" * 3000
      expect { subject.deliver(message, device) }.to raise_error(Pling::DeliveryFailed, /Payload size of \d+ exceeds allowed size of 2048 bytes/)
    end

    it 'should try to deliver the given message' do
      expected_header  = "\x00\x00 \x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00$"
      expected_payload = {
        'aps' => {
          'alert' => 'Hello from Pling'
        }
      }

      connection.stub(:write) do |packet|
        header, payload = packet[0..36], packet[37..-1]
        header.should eq(expected_header)
        JSON.parse(payload).should eq(expected_payload)
      end

      subject.deliver(message, device)
    end

    it 'should include the given badge' do
      expected_payload = {
        'aps' => {
          'alert' => 'Hello from Pling',
          'badge' => 10
        }
      }

      connection.stub(:write) do |packet|
        JSON.parse(packet[37..-1]).should eq(expected_payload)
      end

      message.badge = 10

      subject.deliver(message, device)
    end

    it 'should include the given badge' do
      expected_payload = {
        'aps' => {
          'alert' => 'Hello from Pling',
          'sound' => 'pling'
        }
      }

      connection.stub(:write) do |packet|
        JSON.parse(packet[37..-1]).should eq(expected_payload)
      end

      message.sound = :pling

      subject.deliver(message, device)
    end

    it 'should include the given content_available flag' do
      expected_payload = {
        'aps' => {
          'alert' => 'Hello from Pling',
          'content-available' => 1
        }
      }

      connection.stub(:write) do |packet|
        JSON.parse(packet[37..-1]).should eq(expected_payload)
      end

      message.content_available = 1

      subject.deliver(message, device)
    end

    it 'should include the given category' do
      expected_payload = {
        'aps' => {
          'alert' => 'Hello from Pling',
          'category' => 'foobar'
        }
      }

      connection.stub(:write) do |packet|
        JSON.parse(packet[37..-1]).should eq(expected_payload)
      end

      message.category = 'foobar'

      subject.deliver(message, device)
    end

    context 'when configured to include payload' do
      before do
        valid_configuration.merge!(:payload => true)
        message.payload = { :data => 'available' }
      end

      it 'should include the given payload' do
        expected_payload = {
          'aps' => {
            'alert' => 'Hello from Pling'
          },
          'data' => 'available'
        }

        connection.stub(:write) do |packet|
          JSON.parse(packet[37..-1]).should eq(expected_payload)
        end

        subject.deliver(message, device)
      end
    end

    context 'when configured to not include payload' do
      before do
        valid_configuration.merge!(:payload => false)
        message.payload = { :data => 'available' }
      end

      it 'should not include the given payload' do
        expected_payload = {
          'aps' => {
            'alert' => 'Hello from Pling'
          }
        }

        connection.stub(:write) do |packet|
          JSON.parse(packet[37..-1]).should eq(expected_payload)
        end

        subject.deliver(message, device)
      end
    end
  end
end
