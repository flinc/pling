require 'spec_helper'

describe Pling::APN::Feedback do

  let(:connection) { double(Pling::APN::Connection, :closed? => false).as_null_object }

  before do
    Pling::APN::Connection.stub(:new).and_return(connection)
  end

  it { should respond_to(:get) }

end
