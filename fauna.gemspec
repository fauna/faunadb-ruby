# -*- encoding: utf-8 -*-
# stub: fauna 1.3.4 ruby lib

Gem::Specification.new do |s|
  s.name = 'fauna'
  s.version = '1.3.4'
  s.license = 'MPL-2.0'
  s.summary = 'FaunaDB Ruby client.'
  s.description = 'Ruby client for the Fauna distributed database.'
  s.authors = ['Fauna, Inc.']
  s.email = 'priority@faunadb.com'
  s.files = %w(CHANGELOG Gemfile LICENSE Manifest README.md Rakefile fauna.gemspec lib/fauna.rb lib/fauna/client.rb lib/fauna/connection.rb lib/fauna/errors.rb lib/fauna/objects.rb lib/fauna/query.rb lib/fauna/util.rb test/class_test.rb test/client_test.rb test/connection_test.rb test/database_test.rb test/query_test.rb test/readme_test.rb test/set_test.rb test/test_helper.rb)
  s.homepage = 'https://github.com/faunadb/faunadb-ruby'
  s.date = '2015-01-14'
  s.extra_rdoc_files = %w(CHANGELOG LICENSE README.md lib/fauna/client.rb lib/fauna/connection.rb lib/fauna/errors.rb lib/fauna/objects.rb lib/fauna/query.rb lib/fauna/util.rb)
  s.rdoc_options = %w(--line-numbers --title Fauna --main README.md)
  s.test_files = %w(test/class_test.rb test/client_test.rb test/connection_test.rb test/database_test.rb test/query_test.rb test/readme_test.rb test/set_test.rb test/test_helper.rb)
  s.require_paths = ['lib']
  s.required_rubygems_version = Gem::Requirement.new('>= 1.2') if s.respond_to? :required_rubygems_version=
  s.rubyforge_project = 'fauna'
  s.rubygems_version = '2.1.10'

  if s.respond_to? :specification_version
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0')
      s.add_runtime_dependency(%q<faraday>, ['~> 0.9.0'])
      s.add_runtime_dependency(%q<json>, ['~> 1.8.0'])
      s.add_development_dependency(%q<mocha>, ['>= 0'])
      s.add_development_dependency(%q<echoe>, ['>= 0'])
      s.add_development_dependency(%q<minitest>, ['~> 4.0'])
      s.add_development_dependency(%q<rubocop>, ['>= 0'])
    else
      s.add_dependency(%q<faraday>, ['~> 0.9.0'])
      s.add_dependency(%q<json>, ['~> 1.8.0'])
      s.add_dependency(%q<mocha>, ['>= 0'])
      s.add_dependency(%q<echoe>, ['>= 0'])
      s.add_dependency(%q<minitest>, ['~> 4.0'])
      s.add_dependency(%q<rubocop>, ['>= 0'])
    end
  else
    s.add_dependency(%q<faraday>, ['~> 0.9.0'])
    s.add_dependency(%q<json>, ['~> 1.8.0'])
    s.add_dependency(%q<mocha>, ['>= 0'])
    s.add_dependency(%q<echoe>, ['>= 0'])
    s.add_dependency(%q<minitest>, ['~> 4.0'])
    s.add_dependency(%q<rubocop>, ['>= 0'])
  end
end
