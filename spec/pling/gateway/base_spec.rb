require 'spec_helper'

describe Pling::Gateway::Base do

  describe '#handles?' do
    let(:gateway_class) do
      Class.new(Pling::Gateway::Base).tap do |klass|
        klass.handles :android, :c2dm
      end
    end

    let(:gateway) { gateway_class.new }
    let(:device) { Pling::Device.new }

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

end
