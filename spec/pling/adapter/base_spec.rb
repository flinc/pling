require 'spec_helper'

describe Pling::Adapter::Base do

  describe '.deliver' do

    let(:device)  { Pling::Device.new }
    let(:message) { Pling::Message.new }
    let(:gateway) { double(:gateway_double, :deliver => true) }

    it 'should try to discover a gateway' do
      Pling::Gateway.should_receive(:discover).with(device).and_return(gateway)
      subject.deliver(message, device)
    end

    it 'should try to deliver to the discoveredgateway' do
      gateway.should_receive(:deliver).with(message, device)
      Pling::Gateway.stub(:discover).and_return(gateway)
      subject.deliver(message, device)
    end
  end
end
