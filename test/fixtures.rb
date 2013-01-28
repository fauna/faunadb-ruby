class Fauna::User
  field :pockets
end

class Fauna::Publisher
  field :visited
end

class Pig < Fauna::Class
  field :name, :visited
  timeline :visions
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
  timeline :posts
end

class Post < Fauna::Class
  field :body
end

Fauna.schema do |f|
  f.timeline :visions
  f.timeline :posts

  f.resource "classes/pig", :class => Pig
  f.resource "classes/pigkeeper", :class => Pigkeeper
  f.resource "classes/vision", :class => Vision
  f.resource "classes/message_board", :class => MessageBoard
  f.resource "classes/post", :class => Post
end
