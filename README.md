# Fauna

Ruby client for the [Fauna](http://fauna.org) API.

## Installation

The Fauna ruby client is distributed as a gem. Install it via:

    $ gem install fauna

Or if you use Bundler, add it to your application's `Gemfile`:

    gem 'fauna'

And then execute:

    $ bundle

## Compatibility

Tested and compatible with MRI 1.9.3. Other Rubies may also work.

## Basic Usage

First, require the gem:

```ruby
require "rubygems"
require "fauna"
```

### Configuring the API

All API requests start with an instance of `Fauna::Connection`.

Creating a connection requires either a token, a server key, a
client key, or the database's email and password.

Let's use the email and password to get a server key:

```ruby
root = Fauna::Connection.new(email: "database@example.com", password: "secret")
server_key = root.post("keys/server")['resource']['key']
```

Now we can make a global database-level connection:

```ruby
$fauna = Fauna::Connection.new(server_key: server_key)
```

You can optionally configure a `logger` on the connection to ease
debugging:

```ruby
require "logger"
$fauna = Fauna::Connection.new(
  server_key: server_key,
  logger: Logger.new(STDERR))
```

### Client Contexts

The easiest way to work with a connection is to open up a *client
context*, and then manipulate resources within that context:

```ruby
Fauna::Client.context($fauna) do
  user = Fauna::User.create!(email: "taran@example.com")
  user.data["name"] = "Taran"
  user.data["profession"] = "Pigkeeper"
  user.save!
  user.destroy
end
```

By working within a context, not only are you able to use a more
convienient, object-oriented API, you also gain the advantage of
in-process caching.

Within a context block, requests for a resource that has already been
loaded via a previous request will be returned from the cache and no
query will be issued. This substantially lowers network overhead,
since Fauna makes an effort to return related resources as part of
every response.

### Fauna::Resource

All instances of fauna classes have built-in accessors for common
fields:

```ruby
Fauna::Client.context($fauna) do
  user = Fauna::User.create(constraints: "taran77")

  # fields
  user.ref       # => "users/123"
  user.ts        # => 2013-01-30 13:02:46 -0800
  user.deleted   # => false
  user.constraints # => "taran77"

  # data and references
  user.data       # => {}
  user.references # => {}

  # changes event set
  user.changes
end
```

## Rails Usage

Fauna provides ActiveModel-compatible classes that can be used
directly in Rails.

Fauna also provides a Rails helper that sets up a default context in
controllers, based on credentials in `config/fauna.yml`:

```yaml
development:
  email: taran@example.com
  password: secret
  server_key: secret_key
test:
  email: taran@example.com
  password: secret
```

(In `config/fauna.yml`, if an existing server key is specified, the
email and password can be omitted. If a server key is not
specified, a new one will be created each time the app is started.)

Then, in `config/initializers/fauna.rb`:

```ruby
require "fauna/rails"

Fauna.schema do
  # See below for schema setup
end
```

### Setting Up the Schema

First, create some Ruby classes to model your domain. They must
inherit from the `Fauna::Class` base class:

```ruby
# Create a custom Pig class.
class Pig < Fauna::Class
    # Fields can be configured dynamically
    field :name, :title
end

# Create a custom Vision class
class Vision < Fauna::Class
  field :pronouncement
  reference :pig
end
```

Fields and references can be configured dynamically, but the classes
and event sets themselves must be configured with an additional
`Fauna.schema` block (normally placed in
`config/initializers/fauna.rb`):

```ruby
Fauna.schema do
  with Pig do
    # Add a custom event set
    event_set :visions
  end

  with Vision
end
```

Install your schema on the server via the `fauna:migrate` Rake task,
or directly from the Rails console:

```ruby
Fauna::Client.context(Fauna.connection) do
  Fauna.migrate_schema!
end
```

Make sure to do this at least once, as well as every time you change
the schema definition:

### Users Class

```ruby
class Fauna::User
  # Extend the User class with a custom field
  field :pockets
end

# Create a user, fill their pockets, and delete them.
Fauna::Client.context($fauna) do
  taran = Fauna::User.new(
    email: "taran@example.com",
    password: "secret")

  taran.save!
  taran.pockets = "Piggy treats"
  taran.save!
  taran.destroy
end
```

### Custom Classes

```ruby
# Create, find, update, and destroy Pigs.
Fauna::Client.context($fauna) do
  @pig = Pig.create!(name: "Henwen", constraints: "henwen")

  @pig = Pig.find(@pig.id)
  @pig.update(title: "Oracular Swine")

  @pig.title = "Most Illustrious Oracular Swine"
  @pig.save!

  @pig.destroy
end
```

### Event Sets

[Event Sets](https://fauna.org/API#event-sets) are high-cardinality,
bidirectional event collections. Event sets must be declared in the
Schema.

```ruby
Fauna::Client.context($fauna) do
  @pig = Pig.create!(name: "Henwen", constraints: "henwen")

  @vision = Vision.create!(pronouncement: "In an ominous tower...")
  @pig.visions.add @vision

  page = @pig.visions.page(:size => 2)
  page.events.first.resource # => @vision

  next_page = @pig.visions.page(:size => 2, :before => page.before)
  prev_page = @pig.visions.page(:size => 2, :after => page.after)
end
```

### References

References are single or low-cardinality, unidirectional, and have no
event log. They are declared dynamically, in the class.

```ruby
class Vision
  # References can be configured dynamically, like fields
  reference :pig
end

Fauna::Client.context($fauna) do
  @vision.pig # => @pig
  @vision.pig_ref # => "instances/1235921393191239"
end
```

## Further Reading

Please see the Fauna [REST Documentation](https://fauna.org/API) for a
complete API reference, or look in
[`/test`](https://github.com/fauna/fauna-ruby/tree/master/test) for
more examples.

## Contributing

GitHub pull requests are very welcome.

## LICENSE

Copyright 2013 [Fauna, Inc.](https://fauna.org/)

Licensed under the Mozilla Public License, Version 2.0 (the
"License"); you may not use this software except in compliance with
the License. You may obtain a copy of the License at

[http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/)

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
implied. See the License for the specific language governing
permissions and limitations under the License.
