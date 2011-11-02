require 'spec_helper'

describe Pling::Gateway do

  subject { Pling::Gateway }

  let(:message) { Pling::Message.new('Hello from Pling') }
  let(:device)  { Pling::Device.new(:identifier => 'DEVICEIDENTIFIER', :type => :android) }

  let(:gateway_class) do
    Class.new(Pling::Gateway).tap do |klass|
      klass.instance_eval do
        handles :android, :c2dm
      end
    end
  end

  let(:gateway) { gateway_class.new }

  before { Pling.stub(:gateways).and_return(Pling::DelayedInitializer.new([gateway])) }

  it { should respond_to(:discover) }

  describe '.discover' do
    it 'should do a delayed initialization' do
      Pling.stub(:gateways).and_return(Pling::DelayedInitializer.new([[gateway_class, { :some => :option }]]))
      gateway_class.should_receive(:new).with({ :some => :option }).and_return(mock.as_null_object)
      subject.discover(device)
    end

    it 'should require an argument' do
      expect { subject.discover }.to raise_error ArgumentError
    end

    it 'should call #to_pling_device on the given argument' do
      device.should_receive(:to_pling_device).at_least(1).times.and_return(device)
      subject.discover(device)
    end

    it 'should return a gateway that can handle the given device' do
      subject.discover(device).should be == gateway
    end

    it 'should raise an Pling::NoGatewayFound error if no gateway was found' do
      device.type = :random
      expect { subject.discover(device) }.to raise_error Pling::NoGatewayFound, /Could not find a gateway for Pling::Device with type :random/
    end
  end

  describe '#handles?' do
    it 'should return true if the gateway supports the given device\'s type' do
      device.type = :android
      gateway.handles?(device).should be_true

      device.type = :c2dm
      gateway.handles?(device).should be_true
    end

    it 'should return false if the gateway does not support the given device\'s type' do
      device.type = :random
      gateway.handles?(device).should be_false
    end
  end

  describe '#deliver' do

    it 'should call each middleware in the given order' do
      first_middleware = double(Pling::Middleware::Base)
      first_middleware.should_receive(:deliver).
        with(message, device).and_yield(message, device)

      second_middleware = double(Pling::Middleware::Base)
      second_middleware.should_receive(:deliver).
        with(message, device)

      gateway = gateway_class.new(:middlewares => [first_middleware, second_middleware])
      gateway.stub(:deliver!)

      gateway.deliver(message, device)
    end

    it 'should raise an error if #deliver! is not overwritten' do
      expect { gateway.deliver(message, device) }.to raise_error(/Please implement/)
    end

    it 'should not modify the middleware configuration' do
      middlewares = [Pling::Middleware::Base.new, Pling::Middleware::Base.new]

      gateway = gateway_class.new(:middlewares => middlewares)
      gateway.stub(:deliver!)

      expect { gateway.deliver(message, device) }.to_not change(middlewares, :count)
    end

    it 'should raise an Pling::Errors if no on_exception callback is set' do
      gateway.stub(:deliver!).and_raise(Pling::Error)
      expect { gateway.deliver(message, device) }.to raise_error Pling::Error
    end

    it 'should not raise an Pling::Errors if an on_exception callback is set' do
      gateway = gateway_class.new(:on_exception => lambda {})
      gateway.stub(:deliver!).and_raise(Pling::Error)
      expect { gateway.deliver(message, device) }.to_not raise_error Pling::Error
    end

    it 'should pass the exception to the callback' do
      gateway = gateway_class.new(:on_exception => lambda { |error| error.should be_kind_of Pling::Error })
      gateway.stub(:deliver!).and_raise(Pling::Error)
      gateway.deliver(message, device)
    end
  end
end