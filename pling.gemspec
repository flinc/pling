# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "pling/version"

Gem::Specification.new do |s|
  s.name        = "pling"
  s.version     = Pling::VERSION
  s.authors     = ["Benedikt Deicke", "Konstantin Tennhard", "Christian Bäuerlein"]
  s.email       = ["benedikt@synatic.net", "me@t6d.de", "fabrik42@gmail.com"]
  s.homepage    = "http://flinc.github.com/pling"
  s.summary     = %q{Pling is a notification framework that supports multiple gateways}
  s.description = %q{Pling is a notification framework that supports multiple gateways. Currently supported are Android Push and SMS.}

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_runtime_dependency "faraday", "~> 0.7"
  s.add_runtime_dependency "faraday_middleware", "~> 0.8"
  s.add_runtime_dependency "json", "~> 1.4"
  s.add_runtime_dependency "connection_pool", "~> 2.0"
  s.add_runtime_dependency("jruby-openssl") if RUBY_PLATFORM == 'java'

  s.add_development_dependency "rspec", "~> 2.7"
  s.add_development_dependency "yard", ">= 0.7"
  s.add_development_dependency "rake", ">= 0.9"
end
