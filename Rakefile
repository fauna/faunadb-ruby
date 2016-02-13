require 'rspec/core/rake_task'
require 'rdoc/task'

begin
  require 'rubocop/rake_task'
  RuboCop::RakeTask.new
rescue LoadError
  task :rubocop do
    $stderr.puts 'Rubocop is disabled'
  end
end

RSpec::Core::RakeTask.new(:spec)

RDoc::Task.new do |rdoc|
  rdoc.main = 'README.md'
  rdoc.rdoc_dir = 'doc'
  rdoc.rdoc_files.include('README.md', 'lib/fauna.rb', 'lib/fauna/*.rb')
end

task prerelease: [:spec, :install]
task default: :spec
