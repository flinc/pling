require 'spec_helper'

describe Pling::APN::Connection do

  let(:configuration) do
    {
      :host => "localhost",
      :port => 2195,
      :certificate => "/path/to/certificate.pem"
    }
  end

  let(:ssl_context)      { double(OpenSSL::SSL::SSLContext).as_null_object }
  let(:x509_certificate) { double(OpenSSL::X509::Certificate).as_null_object }
  let(:pkey_rsa)         { double(OpenSSL::PKey::RSA).as_null_object }
  let(:tcp_socket)       { double(TCPSocket).as_null_object }
  let(:ssl_socket)       { double(OpenSSL::SSL::SSLSocket, :closed? => false).as_null_object }

  before do
    File.stub(:read).and_return('')
    OpenSSL::SSL::SSLContext.stub(:new).and_return(ssl_context)
    OpenSSL::X509::Certificate.stub(:new).and_return(x509_certificate)
    OpenSSL::PKey::RSA.stub(:new).and_return(pkey_rsa)
    TCPSocket.stub(:new).and_return(tcp_socket)
    OpenSSL::SSL::SSLSocket.stub(:new).and_return(ssl_socket)
  end

  context "when creating it from a valid configuration" do

    it "should read the certificate" do
      File.should_receive(:read).
        with('/path/to/certificate.pem').
        and_return("--- CERT CONTENT ---")
    end

    it "should create a tcp socket" do
      TCPSocket.should_receive(:new).with("localhost", 2195)
    end

    it "should create a ssl socket" do
      OpenSSL::SSL::SSLSocket.should_receive(:new).with(tcp_socket, ssl_context)
    end

    it "should create a ssl context" do
      OpenSSL::SSL::SSLContext.should_receive(:new).and_return(ssl_context)
      ssl_context.should_receive(:cert=).with(x509_certificate)
      ssl_context.should_receive(:key=).with(pkey_rsa)
    end

    it "should connect the ssl socket" do
      ssl_socket.should_receive(:connect)
    end

    after do
      Pling::APN::Connection.new(configuration)
    end

  end

  context 'when created with an invalid configuration' do

    it "should raise an error when :certificate is missing" do
      expect { Pling::APN::Connection.new({}) }.to raise_error(ArgumentError, /:certificate is missing/)
    end

  end

  context "when writing data" do

    subject do
      Pling::APN::Connection.new(configuration)
    end

    it "should simply pass on the data to the underlying SSL socket" do
      data = 'Pass this through!'
      ssl_socket.should_receive(:write).with(data)
      subject.write(data)
    end
    
    it "should raise an exception it is closed" do
      subject.close
      expect { subject.write("Waahhhh!") }.to raise_error(IOError, "Connection closed")
    end

  end

end
