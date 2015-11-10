require 'spec_helper'

describe Pling::Device do

  context 'when created with no arguments' do
    it 'should not require an argument' do
      expect { Pling::Device.new }.to_not raise_error ArgumentError
    end

    specify { Pling::Device.new.should_not be_valid }
  end

  context 'when created with an empty hash' do
    it 'should accept a hash of attributes' do
      expect { Pling::Device.new({}) }.to_not raise_error
    end

    specify { Pling::Device.new({}).should_not be_valid }
  end

  context 'when created with an hash of valid attributes' do
    subject { Pling::Device.new(:identifier => 'XXXX', :type => 'android') }

    its(:identifier) { should eq('XXXX') }
    its(:type) { should eq(:android) }

    it { should be_valid }
  end

  context 'when created with an hash of invalid attributes' do
    it 'should ignore the invalid paramters' do
      expect { Pling::Device.new({ :random_param => true }) }.to_not raise_error
    end
  end

  describe '#to_pling_device' do
    it 'should return self' do
      subject.to_pling_device.should be === subject
    end
  end

  describe '#identifier=' do
    it 'should call #to_s on the given identifier' do
      subject.identifier = double(:identifier_double, :to_s => 'XXXX')
      subject.identifier.should eq('XXXX')
    end
  end

  describe '#type=' do
    it 'should call #to_sym on the given type' do
      subject.type = 'android'
      subject.type.should eq(:android)
    end
  end

  it { should respond_to :deliver }

  describe '#deliver' do
    subject { Pling::Device.new(:identifier => 'XXXX', :type => 'android') }

    let(:message) { Pling::Message.new }
    let(:gateway) { stub(:deliver => true) }

    before { Pling::Gateway.stub(:discover => gateway) }

    it 'should require a message as parameter' do
      expect { subject.deliver }.to raise_error ArgumentError
    end

    it 'should deliver the given message to an gateway' do
      gateway.should_receive(:deliver).with(message, subject)
      subject.deliver(message)
    end
  end
end
