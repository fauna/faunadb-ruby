# Fauna

Ruby client for the [Fauna](http://fauna.org) API.

## Installation

The Fauna ruby client is distributed as a gem. Install it via:

    $ gem install fauna

Or, add it to your application's `Gemfile`:

    gem 'fauna'

And then execute:

    $ bundle

## Compatibility

Tested and compatible with MRI 1.9.3. Other Rubies may also work.

## Usage

### Getting Started

First, require the gem:

```ruby
require "rubygems"
require "fauna"
```

### Configuring the API

All API requests start with an instance of `Fauna::Connection`.

Creating a connection requires either a token, a publisher key, a
client key, or the publisher's email and password.

Let's use the email and password to get a publisher key:

```ruby
root = Fauna::Connection.new(email: "publisher@example.com", password: "secret")
publisher_key = root.post("keys/publisher")['resource']['key']
```

Now we can make a global publisher-level connection:

```ruby
$fauna = Fauna::Connection.new(publisher_key: publisher_key)
```

You can optionally configure a `logger` on the connection to ease
debugging:

```ruby
require "logger"
$fauna = Fauna::Connection.new(publisher_key: publisher_key, logger:
Logger.new(STDERR))
```

### Client Contexts

The easiest way to work with a connection is to open up a *client
context*, and then manipulate resources within that context:

```ruby
Fauna::Client.context($fauna) do
  user = Fauna::User.create!(name: "Taran", email: "taran@example.com")
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

#### Rails Controllers

If you are using Fauna from Rails, an around filter is a great spot to
set up a default context.

```ruby
class ApplicationController < ActionController::Base
  around_filter :fauna_context

  private

  def fauna_context
    Fauna::Client.context($fauna) do
      yield
    end
  end
end
```

### Setting Up the Schema

First, create your Ruby classes:

```ruby
# Create a custom Pig class.
class Pig < Fauna::Class
    # Fields can be configured dynamically
    field :name, :title
end

# Create a custom Vision class
class Vision < Fauna::Class
  field :text
  reference :pig
end
```

Fields and references can be configured dynamically, but the classes and
timelines themselves must be configured with an additional Schema block:

```ruby
# Declare your domain's schema
Fauna.schema do |f|
  f.resource "pig", :class => Pig do |p|
    # Add a custom timeline
    p.timeline :visions
  end

  f.resource "classes/vision", :class => Vision
end

# Send your schema to the server
Fauna::Client.context($fauna) do
  Fauna.migrate_schema!
end
```

### Model Usage

Fauna provided ActiveModel-compatible classes that can be used
directly, as well as extended for custom types. Examples follow.

#### Users

```ruby
class Fauna::User
  # Extend the User class with a custom field
  field :pockets
end

# Create a user, fill their pockets, and delete them.
Fauna::Client.context($fauna) do
  taran = Fauna::User.new(name: "Taran", email: "taran@example.com", password:
"secret")
  taran.save!
  taran.pockets = "Piggy treats"
  taran.save!
  taran.destroy
end
```

#### Classes and Instances

```ruby
# Create, find, update, and destroy Pigs.
Fauna::Client.context($fauna) do
  @pig = Pig.create!(name: "Henwen", external_id: "henwen")

  @pig = Pig.find(@pig.ref)
  @pig.update(title: "Oracular Swine")

  @pig.title = "Most Illustrious Oracular Swine"
  @pig.save!

  @pig.destroy
end
```

### Associations

Fauna provides two main ways to model associations.

[Timelines](https://fauna.org/API#timelines) are high-cardinality, bidirectional
event collections. Timelines must be declared in the Schema.

```ruby
Fauna::Client.context($fauna) do
  @pig = Pig.create!(name: "Henwen", external_id: "henwen")

  @vision = Vision.create!(message: "A dark, ominous tower.")
  @pig.visions.add @vision
  @pig.visions.page.events.first.resource # => @vision
end
```

References are single or low-cardinality, unidirectional, and have no event log.
They are declared dynamically, in the class.

```ruby
class Vision
  # References can be configured dynamically, like fields
  reference :pig
end

Fauna::Client.context($fauna) do
  @vision = Vision.create!(message: "A dark, ominous tower.", pig: @pig)

  @vision.pig # => @pig
  @vision.pig_ref # => "instances/1235921393191239"
end
```

### Further Reading

Please see the Fauna [REST Documentation](https://fauna.org/API) for a
complete API reference, or look in
[`/tests`](https://github.com/fauna/fauna-ruby/tree/master/test) for more
examples.

## Contributing

GitHub pull requests are very welcome.

## LICENSE

Copyright 2013 [Fauna, Inc.](https://fauna.org/)

Licensed under the Mozilla Public License, Version 2.0 (the "License"); you may
not use this software except in compliance with the License. You may obtain a
copy of the License at

[http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/)

Unless required by applicable law or agreed to in writing, software distributed
under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
CONDITIONS OF ANY KIND, either express or implied. See the License for the
specific language governing permissions and limitations under the License.
