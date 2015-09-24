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

### Creating a Client

All API requests pass through a `Fauna::Client` Creating a client
requires either a token, a server key, or a client key.

```ruby
server_key = 'ls8AkXLdakAAAALPAJFy3LvQAAGwDRAS_Prjy6O8VQBfQAlZzwAA'
```

Now we can make a database-level client:

```ruby
$fauna = Fauna::Client.new(secret: server_key)
```

You can optionally configure a `logger` on the client to ease
debugging:

```ruby
require 'logger'
$fauna = Fauna::Client.new(
  secret: server_key,
  logger: Logger.new(STDERR))
```

### Using the Client

Now that we have a client, we can start performing queries:

```ruby
# Create the user
user = $fauna.query(Fauna::Query.create(Fauna::Ref.new('users'), Fauna::Query.quote('email' => 'taran@example.com')))

# Update the user's data
user = $fauna.query(Fauna::Query.update(user['ref'], Fauna::Query.quote('data' => {'name' => 'Taran', 'profession' => 'Pigkeeper'})))

# Delete the user
$fauna.query(Fauna::Query.delete(user['ref']))
```

## Running Tests

You can run tests against FaunaDB Cloud. Set the `FAUNA_ROOT_KEY` environment variable to your CGI-escaped email and password, joined by a `:`. Then run `rake test`:

```bash
export FAUNA_ROOT_KEY='test%40faunadb.com:secret'
rake test
```

To run a single test, use e.g. `ruby -Ilib:test test/client_test.rb`.

## Documenting

Use `bundle exec rake rdoc` to generate documentation.

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
