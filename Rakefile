#!/usr/bin/env rake
require 'rake/testtask'

Rake::TestTask.new(:test) do |t|
  t.libs << '../lib'
  t.libs << '../test'
  t.test_files = FileList['test/*_test.rb']
  t.verbose = true
  t.warning = true
end

task :default => :test
