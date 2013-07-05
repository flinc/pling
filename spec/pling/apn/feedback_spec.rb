require 'spec_helper'

describe Pling::APN::Feedback do
  
  let(:connection) { double(Pling::APN::Connection, :closed? => false).as_null_object }
  
  let(:time) { Time.now.to_i }
  
  # Simulate device tokens of _different_ length! A device token is _not_
  # necessarily 32 byte long. Check the documentation if you don't belive it. :)
  # http://bit.ly/apple-apn-feedback-documentation
  let(:token_0) { "0" * 64 }
  let(:token_1) { "00000000000000000000000000000001" }
  
  let(:feedback_0) { [time, 32, token_0].pack("NnH*") }
  let(:feedback_1) { [time, 16, token_1].pack("NnH*") }
  
  subject do
    described_class.new(:certificate => '/path/to/certificate.pem')
  end
  
  before do
    Pling::APN::Connection.stub(:new).and_return(connection)
    connection.stub(:gets).and_return(nil)
  end

  it { should respond_to(:get) }
  
  context "when getting feedback" do
    
    it "should be in form of a list" do
      subject.get.should be_kind_of(Array)
    end
    
    it "should contain all tokens send by Apple" do
      connection.stub(:gets).and_return(feedback_0, feedback_1, nil)
      tokens = subject.get
      
      tokens.should be == [token_0, token_1]
    end

    it "closes the connection after receiving all tokens" do
      connection.should_receive(:close)

      subject.get
    end
    
  end

end
