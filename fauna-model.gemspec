# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = 'fauna-model'
  s.version = '2.0.0'
  s.author = 'Fauna, Inc.'
  s.email = 'priority@faunadb.com'
  s.summary = 'FaunaDB Ruby client model.'
  s.description = 'Ruby model for the FaunaDB client.'
  s.homepage = 'https://github.com/faunadb/faunadb-ruby'
  s.license = 'MPL-2.0'

  s.files = %w(CHANGELOG Gemfile LICENSE README.md Rakefile fauna_model.gemspec lib/fauna_model.rb lib/fauna_model/base.rb lib/fauna_model/errors.rb lib/fauna_model/page.rb)
  s.extra_rdoc_files = %w(CHANGELOG LICENSE README.md)
  s.rdoc_options = %w(--line-numbers --title="Fauna Model" --main README.md)
  s.test_files = %w()
  s.require_paths = ['lib']

  s.add_runtime_dependency 'fauna', '= 2.0.0'
  s.add_runtime_dependency 'activemodel', '= 4.1.4'
  s.add_development_dependency 'mocha', '>= 0'
  s.add_development_dependency 'minitest', '~> 5.1'
  s.add_development_dependency 'rubocop', '>= 0'
end