require 'rubygems'
require 'bundler'

require 'rspec/its'
Bundler.require

Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

RSpec.configure do |config|
  config.mock_with :rspec do |mocks|
    mocks.syntax = [:should, :expect]
  end

  config.expect_with :rspec do |expectations|
    expectations.syntax = [:should, :expect]
  end
end
