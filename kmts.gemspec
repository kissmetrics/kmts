# -*- encoding: utf-8 -*-
require File.expand_path("../lib/kmts/version", __FILE__)

Gem::Specification.new do |s|
  s.name        = "kmts"
  s.version     = KMTS::VERSION
  s.platform    = Gem::Platform::RUBY
  s.license     = "Apache-2.0"
  s.authors     = ["Kissmetrics"]
  s.email       = ["support@kissmetrics.io"]
  s.homepage    = "https://github.com/kissmetrics/kmts"
  s.summary     = "Threadsafe Ruby gem for Kissmetrics tracking API"
  s.description = "A threadsafe Ruby gem that can be used to interact with the Kissmetrics tracking API."

  s.required_rubygems_version = ">= 1.3.6"
  s.rubyforge_project         = "kissmetrics"

  s.add_development_dependency "bundler", "~> 1.13"
  s.add_development_dependency "rspec", "~> 3.5"
  s.add_development_dependency "rake", "~> 13.0"
  s.add_development_dependency "json", "~> 2.0"

  s.files        = `git ls-files`.split("\n")
  s.test_files   = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables  = `git ls-files`.split("\n").map{|f| f =~ /^bin\/(.*)/ ? $1 : nil}.compact
  s.require_path = 'lib'
end
