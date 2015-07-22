# FaunaDB

Experimental Ruby client for [FaunaDB](https://faunadb.com).

## Installation

The FaunaDB ruby client is distributed as a gem. Install it via:

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
require 'rubygems'
require 'fauna'
```

### Creating a Connection

All API requests pass through a `Fauna::Client`, which wraps around
a `Fauna::Connection` instance.

Creating a connection requires either a token, a server key, or a
client key.

```ruby
server_key = 'ls8AkXLdakAAAALPAJFy3LvQAAGwDRAS_Prjy6O8VQBfQAlZzwAA'
```

Now we can make a database-level connection:

```ruby
$fauna = Fauna::Connection.new(secret: server_key)
```

You can optionally configure a `logger` on the connection to ease
debugging:

```ruby
require 'logger'
$fauna = Fauna::Connection.new(
  secret: server_key,
  logger: Logger.new(STDERR))
```

### Client

Now that we have a connection, we need to create a client. The standard
way to do this is by creating a client with the connection:

```ruby
client = Fauna::Client.new($fauna)
user = client.query(Fauna::Query.create(Fauna::Ref.new('users'), Fauna::Query.quote('email' => 'taran@example.com')))
user = client.query(Fauna::Query.update(user['resource']['ref'], Fauna::Query.quote('data' => {'name' => 'Taran', 'profession' => 'Pigkeeper'})))
client.query(Fauna::Query.delete(user['resource']['ref']))
```

## Running Tests

You can run tests against FaunaDB Cloud. Set the `FAUNA_ROOT_KEY` environment variable to your CGI-escaped email and password, joined by a `:`. Then run `rake`:

```bash
export FAUNA_ROOT_KEY='test%40faunadb.com:secret'
rake
```

## Further Reading

Please see the [FaunaDB Documentation](https://faunadb.com/documentation) for
a complete API reference, or look in
[`/test`](https://github.com/faunadb/faunadb-ruby/tree/master/test) for more
examples.

## Contributing

GitHub pull requests are very welcome.

## LICENSE

Copyright 2015 [Fauna, Inc.](https://faunadb.com/)

Licensed under the Mozilla Public License, Version 2.0 (the
"License"); you may not use this software except in compliance with
the License. You may obtain a copy of the License at

[http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/)

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
implied. See the License for the specific language governing
permissions and limitations under the License.
