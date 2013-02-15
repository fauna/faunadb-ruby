# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "fauna"
  s.version = "0.1.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 1.2") if s.respond_to? :required_rubygems_version=
  s.authors = ["Fauna, Inc."]
  s.date = "2013-02-15"
  s.description = "Official Ruby client for the Fauna API."
  s.email = ""
  s.extra_rdoc_files = ["CHANGELOG", "LICENSE", "README.md", "lib/fauna.rb", "lib/fauna/client.rb", "lib/fauna/connection.rb", "lib/fauna/ddl.rb", "lib/fauna/model.rb", "lib/fauna/model/class.rb", "lib/fauna/model/follow.rb", "lib/fauna/model/publisher.rb", "lib/fauna/model/timeline.rb", "lib/fauna/model/user.rb", "lib/fauna/rails.rb", "lib/fauna/resource.rb"]
  s.files = ["CHANGELOG", "Gemfile", "LICENSE", "Manifest", "README.md", "Rakefile", "fauna.gemspec", "lib/fauna.rb", "lib/fauna/client.rb", "lib/fauna/connection.rb", "lib/fauna/ddl.rb", "lib/fauna/model.rb", "lib/fauna/model/class.rb", "lib/fauna/model/follow.rb", "lib/fauna/model/publisher.rb", "lib/fauna/model/timeline.rb", "lib/fauna/model/user.rb", "lib/fauna/rails.rb", "lib/fauna/resource.rb", "test/client_test.rb", "test/connection_test.rb", "test/fixtures.rb", "test/model/association_test.rb", "test/model/class_test.rb", "test/model/follow_test.rb", "test/model/publisher_test.rb", "test/model/timeline_test.rb", "test/model/user_test.rb", "test/model/validation_test.rb", "test/readme_test.rb", "test/test_helper.rb"]
  s.homepage = "http://fauna.github.com/fauna/"
  s.rdoc_options = ["--line-numbers", "--inline-source", "--title", "Fauna", "--main", "README.md"]
  s.require_paths = ["lib"]
  s.rubyforge_project = "fauna"
  s.rubygems_version = "1.8.23"
  s.summary = "Official Ruby client for the Fauna API."
  s.test_files = ["test/client_test.rb", "test/connection_test.rb", "test/model/association_test.rb", "test/model/class_test.rb", "test/model/follow_test.rb", "test/model/publisher_test.rb", "test/model/timeline_test.rb", "test/model/user_test.rb", "test/model/validation_test.rb", "test/readme_test.rb", "test/test_helper.rb"]

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
