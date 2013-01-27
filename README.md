# Fauna

Ruby client for the [Fauna](http://fauna.org) API

## Installation

The Fauna ruby client is distributed as a gem. Simply install it via

    $ gem install fauna

Add it to your application's Gemfile:

    gem 'fauna'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install fauna

## Compatibility

This library relies on rest-client, and requires basic Net::HTTP
compatibility, so pretty much any ruby version should work. It has
been testing with the following:

  - MRI 1.9.3
  - MRI 2.0.0-rc1
  - JRuby 1.6.8
  - Rubinius 2.0.0-rc1

Reports about other rubies are welcome.

## Usage

### Configuring a connection

All roads lead to Rome, and all API requests start with an instance Fauna::Connection.

Creating a connection requires a user `token`, a `publisher_key` a
`client_key`, or the publisher's `email` and `password`:

```ruby
conn = Fauna::Connection.new publisher_key: 'AQAAVMMNr2AAAQBUww2TwAABmSDLUjXGqk4gr44fwPPWog'
```

or

```ruby
conn = Fauna::Connection.new email: 'mr_publisher@example.com', password: 'supersekrit'
```

### Client Contexts

The most efficient way to work with a connection is to open up a
*client context*, and then work with the various resource
representation classes within that context:

```ruby
Fauna::Client.context connection do
  user = Fauna::User.find("users/123")
  user.data['age'] = 21
  user.save
end
```

By working within a context, not only are you able to use a more
convienient, object-oriented API (no need to pass along the connection
object to every method. The existing connection is pulled out of a
thread local variable), you also take advantage of built-in request
caching.

For the life of the context (i.e. within the block passed to
`context`), requests for a resource that has been seen already,
whether in a previous request or in a [`references` hash][1], will
pull from the cache rather than hitting the API. The result is an easy
to use, object-oriented API that maintains low communication overhead,
without the need for manual, involved request tracking.

If you are using Fauna from Rails or another web framework, an around
filter is a great spot to setup and tear down a context.

```ruby
class ApplicationController < ActionController::Base
  around_filter :open_fauna_context

  private

  def open_fauna_context
    Fauna::Client.context $fauna_connection do
      yield
    end
  end
end
```

### Classes

The classes can be managed through the ``Fauna::Class`` wrapper class,
this can be used to create, find, update and delete classes:

```ruby
# Create henwen class
Fauna::Class.create("henwen")

# You can also add arbitrary data to classes on creation
Fauna::Class.create("henwen", "name" => "Hen Wen")

# Update henwen class data
Fauna::Class.update("henwen", "name" => "Henwen")

# Find all classes
classes = Fauna::Class.find("classes")

# Find henwen class
henwen = Fauna::Class.find("classes/henwen")

# Delete henwen class
henwen = Fauna::Class.delete("classes/henwen")
```

### Instances

Instances of classes can be managed with the ``Fauna::Instance``
wrapper:

```ruby
# Create an instance of henwen class
Fauna::Instance.create("henwen")

# Create an instance of henwen class with arbritary data
instance = Fauna::Instance.create("henwen", "used" => false)

# Save ref for use in future (ex. instances/20735848002617345)
ref = instance['resource']['ref']

# Update an instance using the ref
Fauna::Instance.update(ref, "used" => true)

# Delete an instance using the ref
Fauna::Instance.delete(ref)
```

### Timeline Settings

Custom Timelines can be managed with the ``Fauna::TimelineSettings``
wrapper:

```ruby
# Create a timeline named comments and set permission for actions
Fauna::TimelineSettings.create("comments", "read" => "everyone", "write" => "follows", "notify" => "followers")

# Update settings of a timeline
Fauna::TimelineSettings.update("timelines/comments", "read" => "everyone", "write" => "everyone", "notify" => "followers"))

# Delete a timeline using the ref
Fauna::TimelineSettings.delete("timelines/comments")
```

### Timeline Events

Events are added to timelines with the ``Fauna::Event`` wrapper, a full
example of use with other resources:

```ruby
Fauna::TimelineSettings.create("comments", "read" => "everyone", "write" => "follows", "notify" => "followers")

Fauna::Class.create("post")
Fauna::Class.create("comment")

post = Fauna::Instance.create("post", "title" => "My first post", "content" => "Hello World")
post_ref = post["resource"]["ref"]

comment = Fauna::Instance.create("post", "body" => "Comment")
comment_ref = comment["resource"]["ref"]

# Add event to a timeline
Fauna::Event.create("#{post_ref}/timelines/comments", comment_ref)

# Retrieve all the events of the timeline
events = Fauna::Event.find("#{post_ref}/timelines/comments")

# Delete event from timeline
Fauna::Event.delete("#{post_ref}/timelines/comments", comment_ref)
```


## Contributing

Pull requests are welcome. To make all our lives easier, please
provide your proposed change via a topical feature branch.

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
