# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = 'fauna'
  s.version = '2.0.0'
  s.author = 'Fauna, Inc.'
  s.email = 'priority@faunadb.com'
  s.summary = 'FaunaDB Ruby client.'
  s.description = 'Ruby client for the Fauna distributed database.'
  s.homepage = 'https://github.com/faunadb/faunadb-ruby'
  s.license = 'MPL-2.0'

  s.files = %w(CHANGELOG Gemfile LICENSE README.md Rakefile fauna.gemspec lib/fauna.rb lib/fauna/client.rb lib/fauna/connection.rb lib/fauna/context.rb lib/fauna/errors.rb lib/fauna/objects.rb lib/fauna/query.rb lib/fauna/resource.rb lib/fauna/util.rb test/client_test.rb test/connection_test.rb test/context_test.rb test/test_helper.rb)
  s.extra_rdoc_files = %w(CHANGELOG LICENSE README.md)
  s.rdoc_options = %w(--line-numbers --title Fauna --main README.md)
  s.test_files = %w(test/client_test.rb test/connection_test.rb test/context_test.rb test/test_helper.rb)
  s.require_paths = ['lib']

  s.add_runtime_dependency 'faraday', '~> 0.9.0'
  s.add_runtime_dependency 'json', '~> 1.8.0'
  s.add_development_dependency 'mocha', '>= 0'
  s.add_development_dependency 'minitest', '~> 5.1'
  s.add_development_dependency 'rubocop', '>= 0'
end
