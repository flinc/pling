require 'spec_helper'

describe Pling::Message do

  context 'when created with no arguments' do
    it 'should not require an argument' do
      expect { Pling::Message.new() }.to_not raise_error ArgumentError
    end

    specify { Pling::Message.new().should_not be_valid }
  end

  context 'when created with a string as first argument' do
    subject { Pling::Message.new('Hello from Pling') }
    its(:body) { should eq('Hello from Pling') }
    it { should be_valid }
  end

  context 'when created with a hash that contains a :body key as first argument' do
    subject { Pling::Message.new(:body => 'Hello from Pling') }
    its(:body) { should eq('Hello from Pling') }
    it { should be_valid }
  end

  context 'when created with a hash that contains a :subject key' do
    subject { Pling::Message.new(:subject => "Hello!")}
    its(:subject) { should eq('Hello!')}
  end

  context 'when created with a hash that contains a :badge key' do
    subject { Pling::Message.new(:badge => 1)}
    its(:badge) { should eq('1') }
  end

  context 'when created with an hash of invalid attributes' do
    it 'should ignore the invalid paramters' do
      expect { Pling::Message.new({ :random_param => true }) }.to_not raise_error
    end
  end

  describe '#body=' do
    it 'should call #to_s on the given body' do
      subject.body = stub(:to_s => 'Hello from Pling')
      subject.body.should eq('Hello from Pling')
    end
  end

  describe '#to_pling_message' do
    it 'should return self' do
      subject.to_pling_message.should be === subject
    end
  end

end
