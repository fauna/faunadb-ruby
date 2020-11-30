# -*- encoding: utf-8 -*-
require './lib/fauna/version'

Gem::Specification.new do |s|
  s.name = 'fauna'
  s.version = Fauna::VERSION.dup
  s.author = 'Fauna, Inc.'
  s.email = 'priority@fauna.com'
  s.summary = 'FaunaDB Ruby driver'
  s.description = "FaunaDB's Ruby driver is now \"community-supported\". If you are using this driver in production, it will continue to work as expected. However, new features won't be exposed in the driver unless the necessary changes are contributed by a community member. Please email product@fauna.com if you have any questions/concerns about the model or would like to take a more active role in the development of the driver (eg. partnering with us and operating as a \"maintainer\" for the driver)."
  s.homepage = 'https://github.com/fauna/faunadb-ruby'
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
  s.add_development_dependency 'simplecov-json', '~> 0.2.0'
  s.add_development_dependency 'rspec_junit_formatter', '~> 0.3.0'
end
