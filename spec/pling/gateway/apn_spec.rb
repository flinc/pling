require 'spec_helper'

describe Pling::Gateway::APN do

  let(:valid_configuration) { { :certificate => '/path/to/certificate.pem' } }

  let(:message) { Pling::Message.new('Hello from Pling') }
  let(:device)  { Pling::Device.new(:identifier => 'DEVICEIDENTIFIER', :type => :iphone) }

  let(:ssl_context)      { double(OpenSSL::SSL::SSLContext).as_null_object }
  let(:x509_certificate) { double(OpenSSL::X509::Certificate).as_null_object }
  let(:pkey_rsa)         { double(OpenSSL::PKey::RSA).as_null_object }
  let(:tcp_socket)       { double(TCPSocket).as_null_object }
  let(:ssl_socket)       { double(OpenSSL::SSL::SSLSocket).as_null_object }

  before do
    File.stub(:read).with('/path/to/certificate.pem').and_return('--- CERT CONTENT ---')
    OpenSSL::SSL::SSLContext.stub(:new).and_return(ssl_context)
    OpenSSL::X509::Certificate.stub(:new).and_return(x509_certificate)
    OpenSSL::PKey::RSA.stub(:new).and_return(pkey_rsa)
    TCPSocket.stub(:new).and_return(tcp_socket)
    OpenSSL::SSL::SSLSocket.stub(:new).and_return(ssl_socket)
  end

  it 'should handle various apn related device types' do
    Pling::Gateway::APN.handled_types.should =~ [:apple, :apn, :ios, :ipad, :iphone, :ipod]
  end

  context 'when created with an invalid configuration' do
    it "should raise an error when :certificate is missing" do
      expect { Pling::Gateway::APN.new({}) }.to raise_error(ArgumentError, /:certificate is missing/)
    end
  end

  context 'when created with a valid configuration' do
    it 'should allow configuration of the :certificate' do
      gateway = Pling::Gateway::APN.new(valid_configuration.merge(:certificate => '/some/path'))
      File.should_receive(:read).with('/some/path').and_return('--- SOME CERT CONTENT ---')
      gateway.deliver(message, device)
    end

    it 'should allow configuration of the :host' do
      gateway = Pling::Gateway::APN.new(valid_configuration.merge(:host => 'some-host'))
      TCPSocket.should_receive(:new).with('some-host', anything).and_return(tcp_socket)
      gateway.deliver(message, device)
    end

    it 'should allow configuration of the :port' do
      gateway = Pling::Gateway::APN.new(valid_configuration.merge(:port => 1234))
      TCPSocket.should_receive(:new).with(anything, 1234).and_return(tcp_socket)
      gateway.deliver(message, device)
    end
  end

  describe '#deliver' do
    subject { Pling::Gateway::APN.new(valid_configuration) }

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
      packet = "\x00\x00 \xDE\xF2\xCE-\xE7\xD2\xF2\xEB\x00" +
               "@{\"aps\":{\"alert\":\"Hello from Pling\"," +
               "\"badge\":0,\"sound\":\"default\"}}"

      ssl_socket.should_receive(:write).with(packet)
      subject.deliver(message, device)
    end
  end
end