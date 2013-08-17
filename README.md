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

Creating a connection requires either a token, a server key, or a
client key.

Let's use a server key we got from our [Fauna Cloud console](https://fauna.org/console):

```ruby
server_key = 'ls8AkXLdakAAAALPAJFy3LvQAAGwDRAS_Prjy6O8VQBfQAlZzwAA'
```
Now we can make a global database-level connection:

```ruby
$fauna = Fauna::Connection.new(secret: server_key)
```

You can optionally configure a `logger` on the connection to ease
debugging:

```ruby
require "logger"
$fauna = Fauna::Connection.new(
  secret: server_key,
  logger: Logger.new(STDERR))
```

### Client Contexts

The easiest way to work with a connection is to open up a *client
context*, and then manipulate resources within that context:

```ruby
Fauna::Client.context($fauna) do
  user = Fauna::Resource.create('users', email: "taran@example.com")
  user.data["name"] = "Taran"
  user.data["profession"] = "Pigkeeper"
  user.save
  user.delete
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
  user = Fauna::Resource.create('users', constraints: "taran77")

  # fields
  user.ref       # => "users/123"
  user.ts        # => 2013-01-30 13:02:46 -0800
  user.deleted   # => false
  user.constraints # => "taran77"

  # data and references
  user.data       # => {}
  user.references # => {}

  # resource events timeline
  user.events
end
```

Fauna resources must be created and accessed by ref, i.e.

```
pig = Fauna::Resource.create 'classes/pigs'
pig.data['name'] = 'Henwen'
pig.save
puts pig.ref # => 'classes/pigs/42471470493859841'

# and later...

pig = Fauna::Resource.find 'classes/pigs/42471470493859841'
# do something with this pig...
````

## Rails Usage

Fauna provides a Rails helper that sets up a default context in
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
