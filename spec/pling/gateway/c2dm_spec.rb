require 'spec_helper'

describe Pling::Gateway::C2DM do

  let(:valid_configuration) do
    { :email => 'someone@gmail.com', :password => 'random', :source => 'some-source' }
  end

  context 'when created with an invalid configuration' do
    [:email, :password, :source].each do |attribute|
      it 'should raise an error when #{attribute} is missing' do
        configuration = valid_configuration
        configuration.delete(attribute)
        expect { Pling::Gateway::C2DM.new(configuration) }.to raise_error(ArgumentError, /#{attribute} is missing/)
      end
    end
  end

  context 'when created with valid configuration' do
    it 'should not raise an error' do
      expect { Pling::Gateway::C2DM.new(valid_configuration) }.to_not raise_error
    end
  end

  describe '#deliver' do
    subject { Pling::Gateway::C2DM.new(valid_configuration) }

    let(:message) { mock(:to_pling_message => Pling::Message.new) }
    let(:device) { mock(:to_pling_device => Pling::Device.new) }

    it "should raise an error if no message is given" do
      expect { subject.deliver(nil, device) }.to raise_error
    end

    it "should raise an error the device is given" do
      expect { subject.deliver(message, nil) }.to raise_error
    end

    it "should call #to_pling_message on the given message" do
      message.should_receive(:to_pling_message)
      subject.deliver(message, device)
    end

    it "should call #to_pling_device on the given device" do
      device.should_receive(:to_pling_device)
      subject.deliver(message, device)
    end
  end
end