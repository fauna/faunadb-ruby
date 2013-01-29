# class Fauna::User
#   field :pockets
# end

# class Fauna::Publisher
#   field :visited
# end

class Fauna::User
  field :pockets
end

class Fauna::Publisher
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
  field :text
  reference :pig
end

class MessageBoard < Fauna::Class
end

class Post < Fauna::Class
  field :body
end

Fauna.schema do |f|
  f.resource "classes/pig", :class => Pig do |r|
    r.timeline :visions
  end

  f.resource "classes/pigkeeper", :class => Pigkeeper

  f.resource "classes/vision", :class => Vision

  f.resource "classes/message_board", :class => MessageBoard do |r|
    r.timeline :posts
  end

  f.resource "classes/post", :class => Post
end
