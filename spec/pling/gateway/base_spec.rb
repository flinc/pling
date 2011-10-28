require 'spec_helper'

describe Pling::Gateway::Base do

  let(:gateway_class) do
    Class.new(Pling::Gateway::Base).tap do |klass|
      klass.handles :android, :c2dm
    end
  end

  let(:gateway) { gateway_class.new }
  let(:message) { Pling::Message.new }
  let(:device) { Pling::Device.new }

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
  end

end
