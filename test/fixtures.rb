# class Fauna::User
#   field :pockets
# end

# class Fauna::Database
#   field :visited
# end

class Fauna::User
  field :name
  field :pockets
end

class Fauna::Database
  field :visited
end

class Pig < Fauna::Class
  field :name, :visited
end

class Pigkeeper < Fauna::Class
  field :visited, :pockets

  validates :visited, :presence => true
  validate :pockets_are_full

  def pockets_are_full
    errors.add :pockets, 'must be full of piggy treats' if pockets <= 0 unless pockets.blank?
  end
end

class Vision < Fauna::Class
  field :pronouncement
  reference :pig
end

class MessageBoard < Fauna::Class
end

class Post < Fauna::Class
  field :body
end

class Comment < Fauna::Class
  field :body
end

Fauna.schema do |f|
  with Pig, :class_name => "classes/pigs" do
    event_set :visions
  end

  with Pigkeeper

  with Vision

  with MessageBoard, :class_name => "classes/board" do
    event_set :posts
  end

  with Post do
    event_set :comments
  end

  with Comment

  # use-case: using the ruby gem to define a schema for another environment.
  with :class_name => "classes/anon"
end
