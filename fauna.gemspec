# -*- encoding: utf-8 -*-
require './lib/fauna/version'

Gem::Specification.new do |s|
  s.name = 'fauna'
  s.version = Fauna::VERSION.dup
  s.author = 'Fauna, Inc.'
  s.email = 'priority@faunadb.com'
  s.summary = 'FaunaDB Ruby driver'
  s.description = 'Ruby driver for FaunaDB.'
  s.homepage = 'https://github.com/faunadb/faunadb-ruby'
  s.license = 'MPL-2.0'

  s.files = %w(CHANGELOG Gemfile LICENSE README.md Rakefile fauna.gemspec lib/fauna.rb) + Dir.glob('lib/fauna/**') + Dir.glob('spec/**')
  s.extra_rdoc_files = %w(CHANGELOG LICENSE README.md)
  s.rdoc_options = %w(--line-numbers --title Fauna --main README.md)
  s.test_files = Dir.glob('spec/**')
  s.require_paths = ['lib']

  s.add_runtime_dependency 'faraday', '~> 0.9.0'
  s.add_runtime_dependency 'net-http-persistent', '~> 2.9'
  s.add_runtime_dependency 'json', '~> 1.8'
  s.add_development_dependency 'rspec', '~> 3.4'
  s.add_development_dependency 'rubocop', '~> 0.38.0'
  s.add_development_dependency 'coveralls', '= 0.8.14'
  s.add_development_dependency 'term-ansicolor', '~> 1.3.0'
end
