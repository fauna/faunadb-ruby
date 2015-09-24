require 'rake/testtask'
require 'rdoc/task'

begin
  require 'rubocop/rake_task'
  RuboCop::RakeTask.new
rescue LoadError
  task :rubocop do
    $stderr.puts 'Rubocop is disabled'
  end
end

Rake::TestTask.new do |t|
  t.test_files = FileList['test/*_test.rb']
end

RDoc::Task.new do |rdoc|
  rdoc.main = 'README.md'
  rdoc.rdoc_dir = 'doc'
  rdoc.rdoc_files.include('README.md', 'lib/fauna.rb', 'lib/fauna/*.rb')
end

task prerelease: [:test, :install]
