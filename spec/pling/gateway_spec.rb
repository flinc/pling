require 'spec_helper'

describe Pling::Gateway do

  subject { Pling::Gateway }

  let(:message) { Pling::Message.new('Hello from Pling') }
  let(:device)  { Pling::Device.new(:identifier => 'DEVICEIDENTIFIER', :type => :android) }

  let(:gateway_class) do
    Class.new(Pling::Gateway::Base).tap do |klass|
      klass.instance_eval do
        handles :android
      end
    end
  end

  let(:gateway) { gateway_class.new }

  before { Pling.stub(:gateways).and_return([gateway]) }

  it { should respond_to(:discover) }

  describe '.discover' do
    it 'should require an argument' do
      expect { subject.discover }.to raise_error ArgumentError
    end

    it 'should call #to_pling_device on the given argument' do
      device.should_receive(:to_pling_device).and_return(device)
      subject.discover(device)
    end

    it 'should return a gateway that can handle the given device' do
      subject.discover(device).should be == gateway
    end

    it 'should raise an Pling::NoGatewayFound error if no gateway was found' do
      device.stub(:type => :random)
      expect { subject.discover(device) }.to raise_error Pling::NoGatewayFound
    end
  end

end