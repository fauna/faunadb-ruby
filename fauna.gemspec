# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'fauna/version'

Gem::Specification.new do |s|
  s.name = 'fauna'
  s.version = Fauna::VERSION
  s.date = '2012-12-10'
  s.summary = ''
  s.description = ''
  s.authors = ["Fauna.org"]
  s.email = 'matt@fauna.org'
  s.files = Dir['README.md', 'lib/**/*']
  s.homepage = 'https://fauna.org'
  s.add_dependency 'rest-client'
  s.add_dependency 'json'
  s.add_development_dependency 'minitest'
  s.add_development_dependency 'activemodel'
end
