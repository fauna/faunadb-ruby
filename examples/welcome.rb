#!/usr/bin/env ruby
# Ruby 1.9 required

require "rubygems"
require "pp"
begin
  require "fauna"
rescue LoadError
  puts "Please run: sudo gem install fauna"
  exit!
end

print "Email: "
email = gets.chomp

print "Password: "
pass = gets.chomp

puts "\nConnected to Fauna Cloud Platform."

puts "\nCreating a server key:"
root = Fauna::Connection.new(email: email, password: pass)
key = root.post("keys/server")['resource']['key']
$fauna = Fauna::Connection.new(server_key: key)
pp key

puts "\nCreating classes:"
class User < Fauna::User
  pp self
end

class Spell < Fauna::Class
  pp self
end

puts "\nCreating an event set."
Fauna.schema do
  with User do
    event_set :spellbook
  end

  with Spell
end

Fauna::Client.context($fauna) do
  puts "\nMigrating."
  Fauna.migrate_schema!

  puts "\nCreating a user:"
  user = User.create!(
    email: "#{object_id}@example.com",
    password: "1234",
    data: {
      name: "Taran",
      profession: "Pigkeeper",
      location: "Caer Dallben"
  })
  pp user.struct

  puts "\nCreating an instance:"
  spell = Spell.create!(
    data: {
      pronouncement: "Draw Dyrnwyn only thou of royal blood.",
      title: "Protector of Dyrnwyn"
  })
  pp spell.struct

  puts "\nAdding the instance to the user's event set."
  user.spellbook.add(spell)

  puts "\nFetching the event set:"
  pp user.spellbook.page.struct
end
