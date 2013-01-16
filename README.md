# Fauna

Ruby Client for [Fauna](http://fauna.org) API

## Installation

Add this line to your application's Gemfile:

    gem 'fauna'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install fauna

## Usage

### Configuring client

To get started configure the client with your publisher key:

```ruby
Fauna.configure do
  config.publisher_key = 'AQAASaskOlAAAQBJqyQLYAABe4PIuvsylBEAUrLuxtKJ8A'
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


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request



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
