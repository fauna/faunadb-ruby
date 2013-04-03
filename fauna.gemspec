# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "fauna"
  s.version = "0.2.6"

  s.required_rubygems_version = Gem::Requirement.new(">= 1.2") if s.respond_to? :required_rubygems_version=
  s.authors = ["Fauna, Inc."]
  s.date = "2013-04-03"
  s.description = "Official Ruby client for the Fauna API."
  s.email = ""
  s.extra_rdoc_files = ["CHANGELOG", "LICENSE", "README.md", "lib/fauna.rb", "lib/fauna/client.rb", "lib/fauna/connection.rb", "lib/fauna/ddl.rb", "lib/fauna/event_set.rb", "lib/fauna/model.rb", "lib/fauna/model/class.rb", "lib/fauna/model/user.rb", "lib/fauna/publisher.rb", "lib/fauna/rails.rb", "lib/fauna/resource.rb", "lib/tasks/fauna.rake"]
  s.files = ["CHANGELOG", "Gemfile", "LICENSE", "Manifest", "README.md", "Rakefile", "examples/welcome.rb", "fauna.gemspec", "lib/fauna.rb", "lib/fauna/client.rb", "lib/fauna/connection.rb", "lib/fauna/ddl.rb", "lib/fauna/event_set.rb", "lib/fauna/model.rb", "lib/fauna/model/class.rb", "lib/fauna/model/user.rb", "lib/fauna/publisher.rb", "lib/fauna/rails.rb", "lib/fauna/resource.rb", "lib/tasks/fauna.rake", "test/association_test.rb", "test/class_test.rb", "test/client_test.rb", "test/connection_test.rb", "test/event_set_test.rb", "test/fixtures.rb", "test/publisher_test.rb", "test/readme_test.rb", "test/test_helper.rb", "test/user_test.rb", "test/validation_test.rb"]
  s.homepage = "http://fauna.github.com/fauna/"
  s.rdoc_options = ["--line-numbers", "--inline-source", "--title", "Fauna", "--main", "README.md"]
  s.require_paths = ["lib"]
  s.rubyforge_project = "fauna"
  s.rubygems_version = "1.8.23"
  s.summary = "Official Ruby client for the Fauna API."
  s.test_files = ["test/association_test.rb", "test/class_test.rb", "test/client_test.rb", "test/connection_test.rb", "test/event_set_test.rb", "test/publisher_test.rb", "test/readme_test.rb", "test/test_helper.rb", "test/user_test.rb", "test/validation_test.rb"]

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<activemodel>, [">= 0"])
      s.add_runtime_dependency(%q<activesupport>, [">= 0"])
      s.add_runtime_dependency(%q<rest-client>, [">= 0"])
      s.add_runtime_dependency(%q<json>, [">= 0"])
      s.add_development_dependency(%q<mocha>, [">= 0"])
      s.add_development_dependency(%q<echoe>, [">= 0"])
      s.add_development_dependency(%q<minitest>, [">= 0"])
    else
      s.add_dependency(%q<activemodel>, [">= 0"])
      s.add_dependency(%q<activesupport>, [">= 0"])
      s.add_dependency(%q<rest-client>, [">= 0"])
      s.add_dependency(%q<json>, [">= 0"])
      s.add_dependency(%q<mocha>, [">= 0"])
      s.add_dependency(%q<echoe>, [">= 0"])
      s.add_dependency(%q<minitest>, [">= 0"])
    end
  else
    s.add_dependency(%q<activemodel>, [">= 0"])
    s.add_dependency(%q<activesupport>, [">= 0"])
    s.add_dependency(%q<rest-client>, [">= 0"])
    s.add_dependency(%q<json>, [">= 0"])
    s.add_dependency(%q<mocha>, [">= 0"])
    s.add_dependency(%q<echoe>, [">= 0"])
    s.add_dependency(%q<minitest>, [">= 0"])
  end
end
