require 'spec_helper'

describe Pling do

  subject { Pling }

  it { should respond_to(:configure) }

  describe '.configure' do
    it 'should require a block' do
      expect { subject.configure }.to raise_error(ArgumentError, /no block given/i)
    end

    it 'should call the block' do
      expect { Pling.configure { throw :executed } }.to throw_symbol(:executed)
    end

    it 'should pass Pling to the block' do
      Pling.configure do |config|
        config.should be(Pling)
      end
    end
  end

  it { should respond_to(:gateways) }
  it { should respond_to(:gateways=) }

  describe '.gateways' do
    it 'should default to an empty array' do
      subject.gateways.should eq([])
    end
  end

end

describe Pling::AuthenticationFailed do
  it { should be_kind_of Pling::Error }
end

describe Pling::DeliveryFailed do
  it { should be_kind_of Pling::Error }
end
