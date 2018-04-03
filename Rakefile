require 'rspec/core/rake_task'
require 'rdoc/task'

RSpec::Core::RakeTask.new(:spec)

RDoc::Task.new do |rdoc|
  rdoc.main = 'README.md'
  rdoc.rdoc_dir = 'doc'
  rdoc.rdoc_files.include('README.md', 'lib/fauna.rb', 'lib/fauna/*.rb')
end

task prerelease: [:spec, :install]
task default: :spec
