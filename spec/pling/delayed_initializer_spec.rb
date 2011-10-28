require 'spec_helper'

describe Pling::DelayedInitializer do

  it { should be_kind_of Array }
  it { should be_empty }

  describe '#initialize!' do
    it 'should initialize all stored arrays' do
      subject << [String, "new string"]
      subject << [String, "other string"]
      subject.initialize!
      subject.should == ["new string", "other string"]
    end

    it 'should not change other object instances' do
      object = Object.new
      subject << object
      subject.initialize!
      subject.first.should be === object
    end
  end

  describe '#use' do
    it 'should add the arguments as an item to the array' do
      subject.use String, "new string"
      subject.should eq([[String, "new string"]])
    end
  end

end