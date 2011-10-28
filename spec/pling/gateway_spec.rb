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
      device.should_receive(:to_pling_device).and_return(device)
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

end