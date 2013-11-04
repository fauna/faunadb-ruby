require 'echoe'

Echoe.new("fauna") do |p|
  p.author = "Fauna, Inc."
  p.project = "fauna"
  p.summary = "Official Ruby client for the Fauna API."
  p.retain_gemspec = true
  p.require_signed
  p.certificate_chain = ["fauna-ruby.pem"]
  p.licenses = ["Mozilla Public License, Version 2.0 (MPL2)"]
  p.dependencies = ["typhoeus", "json"]
  p.development_dependencies = ["mocha", "echoe", "minitest"]
end

task :beautify do
  require "ruby-beautify"
  Dir["**/*rb"].each do |filename|
    s = RBeautify.beautify_string(:ruby, File.read(filename))
    File.write(filename, s) unless s.empty?
   end
end

task :prerelease => [:manifest, :test, :install]
