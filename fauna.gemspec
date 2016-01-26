# -*- encoding: utf-8 -*-
$: << File.expand_path('../lib', __FILE__)
require 'fauna/version'

Gem::Specification.new do |s|
  s.name = 'fauna'
  s.version = Fauna::VERSION
  s.author = 'Fauna, Inc.'
  s.email = 'priority@faunadb.com'
  s.summary = 'FaunaDB Ruby client'
  s.description = 'Ruby client for the Fauna distributed database.'
  s.homepage = 'https://github.com/faunadb/faunadb-ruby'
  s.license = 'MPL-2.0'

  s.files = %w(CHANGELOG Gemfile LICENSE README.md Rakefile fauna.gemspec lib/fauna.rb) + Dir.glob('lib/fauna/**') + Dir.glob('test/**')
  s.extra_rdoc_files = %w(CHANGELOG LICENSE README.md)
  s.rdoc_options = %w(--line-numbers --title Fauna --main README.md)
  s.test_files = Dir.glob('test/**')
  s.require_paths = ['lib']

  s.add_runtime_dependency 'faraday', '~> 0.9.0'
  s.add_runtime_dependency 'json', '~> 1.8'
  s.add_development_dependency 'minitest', '~> 5.8'
  s.add_development_dependency 'rubocop', '~> 0.35.0'
  s.add_development_dependency 'coveralls', '~> 0.8.10'
end
