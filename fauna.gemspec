# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "fauna"
  s.version = "1.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 1.2") if s.respond_to? :required_rubygems_version=
  s.authors = ["Fauna, Inc."]
  s.cert_chain = ["/Users/eweaver/cloudburst/configuration/gem_certificates/gem-public_cert.pem"]
  s.date = "2013-10-22"
  s.description = "Official Ruby client for the Fauna API."
  s.email = ""
  s.extra_rdoc_files = ["CHANGELOG", "LICENSE", "README.md", "lib/fauna.rb", "lib/fauna/cache.rb", "lib/fauna/client.rb", "lib/fauna/connection.rb", "lib/fauna/named_resource.rb", "lib/fauna/rails.rb", "lib/fauna/resource.rb", "lib/fauna/set.rb", "lib/fauna/util.rb", "lib/tasks/fauna.rake"]
  s.files = ["CHANGELOG", "Gemfile", "LICENSE", "Manifest", "README.md", "Rakefile", "fauna.gemspec", "lib/fauna.rb", "lib/fauna/cache.rb", "lib/fauna/client.rb", "lib/fauna/connection.rb", "lib/fauna/named_resource.rb", "lib/fauna/rails.rb", "lib/fauna/resource.rb", "lib/fauna/set.rb", "lib/fauna/util.rb", "lib/tasks/fauna.rake", "test/class_test.rb", "test/client_test.rb", "test/connection_test.rb", "test/database_test.rb", "test/readme_test.rb", "test/set_test.rb", "test/test_helper.rb", "test/query_test.rb"]
  s.homepage = "http://fauna.github.com/fauna/"
  s.rdoc_options = ["--line-numbers", "--inline-source", "--title", "Fauna", "--main", "README.md"]
  s.require_paths = ["lib"]
  s.rubyforge_project = "fauna"
  s.rubygems_version = "2.0.6"
  s.signing_key = "/Users/eweaver/cloudburst/configuration/gem_certificates/gem-private_key.pem"
  s.summary = "Official Ruby client for the Fauna API."
  s.test_files = ["test/class_test.rb", "test/client_test.rb", "test/connection_test.rb", "test/database_test.rb", "test/query_test.rb", "test/readme_test.rb", "test/set_test.rb", "test/test_helper.rb"]

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<typhoeus>, [">= 0"])
      s.add_runtime_dependency(%q<json>, [">= 0"])
      s.add_development_dependency(%q<mocha>, [">= 0"])
      s.add_development_dependency(%q<echoe>, [">= 0"])
      s.add_development_dependency(%q<minitest>, [">= 0"])
    else
      s.add_dependency(%q<typhoeus>, [">= 0"])
      s.add_dependency(%q<json>, [">= 0"])
      s.add_dependency(%q<mocha>, [">= 0"])
      s.add_dependency(%q<echoe>, [">= 0"])
      s.add_dependency(%q<minitest>, [">= 0"])
    end
  else
    s.add_dependency(%q<typhoeus>, [">= 0"])
    s.add_dependency(%q<json>, [">= 0"])
    s.add_dependency(%q<mocha>, [">= 0"])
    s.add_dependency(%q<echoe>, [">= 0"])
    s.add_dependency(%q<minitest>, [">= 0"])
  end
end
