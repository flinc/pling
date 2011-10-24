require 'spec_helper'

describe Pling do

  subject { Pling }

  it { should respond_to(:configure) }

  describe '.configure' do
    it 'should require a block' do
      expect { subject.configure }.to raise_error(ArgumentError, /no block given/i)
    end

    it 'should call the block' do
      expect { Pling.configure { throw :executed } }.to throw_symbol(:executed)
    end

    it 'should pass Pling to the block' do
      Pling.configure do |config|
        config.should be(Pling)
      end
    end
  end

  it { should respond_to(:gateways) }
  it { should respond_to(:gateways=) }

  describe '.gateways' do
    it 'should default to an empty array' do
      subject.gateways.should eq([])
    end
  end

  it { should respond_to(:middlewares) }
  it { should respond_to(:middlewares=) }

  describe '.middlewares' do
    it 'should default to an empty array' do
      subject.middlewares.should eq([])
    end
  end

  it { should respond_to(:adapter) }
  it { should respond_to(:adapter=) }

  describe '.adapter' do
    it 'should default to Pling::Adapter::Base' do
      subject.adapter.class.should eq(Pling::Adapter::Base)
    end
  end

  describe '.deliver' do

    let(:message) { Pling::Message.new }
    let(:device)  { Pling::Device.new  }
    let(:adapter) { mock(:deliver => true) }

    before do
      Pling.stub(:adapter).and_return(adapter)
    end

    it 'should raise an error if no message is given' do
      expect { Pling.deliver(nil, device) }.to raise_error
    end

    it 'should raise an error the device is given' do
      expect { Pling.deliver(message, nil) }.to raise_error
    end

    it 'should call #to_pling_message on the given message' do
      message.should_receive(:to_pling_message).and_return(message)
      Pling.deliver(message, device)
    end

    it 'should call #to_pling_device on the given device' do
      device.should_receive(:to_pling_device).and_return(device)
      Pling.deliver(message, device)
    end

    it 'should call the adapter' do
      adapter.should_receive(:deliver).with(message, device)
      Pling.deliver(message, device)
    end

    it 'should call each middleware in the given order' do
      first_middleware = double(Pling::Middleware::Base)
      first_middleware.should_receive(:deliver).
        with(message, device).and_yield(message, device)

      second_middleware = double(Pling::Middleware::Base)
      second_middleware.should_receive(:deliver).
        with(message, device)

      Pling.stub(:middlewares).and_return([first_middleware, second_middleware])

      Pling.deliver(message, device)
    end
  end
end

describe Pling::AuthenticationFailed do
  it { should be_kind_of Pling::Error }
end

describe Pling::DeliveryFailed do
  it { should be_kind_of Pling::Error }
end

describe Pling::NoGatewayFound do
  it { should be_kind_of Pling::Error }
end
