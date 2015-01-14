# -*- encoding: utf-8 -*-
# stub: fauna 1.3.4 ruby lib

Gem::Specification.new do |s|
  s.name = "fauna"
  s.version = "1.3.4"

  s.required_rubygems_version = Gem::Requirement.new(">= 1.2") if s.respond_to? :required_rubygems_version=
  s.authors = ["Fauna, Inc."]
  s.date = "2015-01-14"
  s.description = "Ruby client for the Fauna distributed database."
  s.email = ""
  s.extra_rdoc_files = ["CHANGELOG", "LICENSE", "README.md", "lib/fauna.rb", "lib/fauna/cache.rb", "lib/fauna/client.rb", "lib/fauna/connection.rb", "lib/fauna/named_resource.rb", "lib/fauna/rails.rb", "lib/fauna/resource.rb", "lib/fauna/set.rb", "lib/fauna/util.rb", "lib/tasks/fauna.rake"]
  s.files = ["CHANGELOG", "Gemfile", "LICENSE", "Manifest", "README.md", "Rakefile", "fauna.gemspec", "lib/fauna.rb", "lib/fauna/cache.rb", "lib/fauna/client.rb", "lib/fauna/connection.rb", "lib/fauna/named_resource.rb", "lib/fauna/rails.rb", "lib/fauna/resource.rb", "lib/fauna/set.rb", "lib/fauna/util.rb", "lib/tasks/fauna.rake", "test/class_test.rb", "test/client_test.rb", "test/connection_test.rb", "test/database_test.rb", "test/query_test.rb", "test/readme_test.rb", "test/set_test.rb", "test/test_helper.rb"]
  s.homepage = "http://fauna.github.com/fauna/"
  s.licenses = ["Mozilla Public License, Version 2.0 (MPL2)"]
  s.rdoc_options = ["--line-numbers", "--title", "Fauna", "--main", "README.md"]
  s.require_paths = ["lib"]
  s.rubyforge_project = "fauna"
  s.rubygems_version = "2.1.10"
  s.summary = "Ruby client for the Fauna distributed database."
  s.test_files = ["test/class_test.rb", "test/client_test.rb", "test/connection_test.rb", "test/database_test.rb", "test/query_test.rb", "test/readme_test.rb", "test/set_test.rb", "test/test_helper.rb"]

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<faraday>, ["~> 0.9.0"])
      s.add_runtime_dependency(%q<json>, ["~> 1.8.0"])
      s.add_development_dependency(%q<mocha>, [">= 0"])
      s.add_development_dependency(%q<echoe>, [">= 0"])
      s.add_development_dependency(%q<minitest>, ["~> 4.0"])
      s.add_development_dependency(%q<rubocop>, [">= 0"])
    else
      s.add_dependency(%q<faraday>, ["~> 0.9.0"])
      s.add_dependency(%q<json>, ["~> 1.8.0"])
      s.add_dependency(%q<mocha>, [">= 0"])
      s.add_dependency(%q<echoe>, [">= 0"])
      s.add_dependency(%q<minitest>, ["~> 4.0"])
      s.add_dependency(%q<rubocop>, [">= 0"])
    end
  else
    s.add_dependency(%q<faraday>, ["~> 0.9.0"])
    s.add_dependency(%q<json>, ["~> 1.8.0"])
    s.add_dependency(%q<mocha>, [">= 0"])
    s.add_dependency(%q<echoe>, [">= 0"])
    s.add_dependency(%q<minitest>, ["~> 4.0"])
    s.add_dependency(%q<rubocop>, [">= 0"])
  end
end
