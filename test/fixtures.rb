# class Fauna::User
#   field :pockets
# end

# class Fauna::Publisher
#   field :visited
# end

class Pig < Fauna::Class
end

class Pigkeeper < Fauna::Class
  validates :visited, :presence => true
  validate :pockets_are_full

  def pockets_are_full
    errors.add :pockets, 'must be full of piggy treats' if pockets <= 0 unless pockets.blank?
  end
end

class Vision < Fauna::Class
end

class MessageBoard < Fauna::Class
end

class Post < Fauna::Class
end

Fauna.schema do |f|
  # f.timeline :visions
  # f.timeline :posts

  f.resource "users" do |user|
    user.field :pockets
  end

  f.resource "publisher" do |p|
    p.field :visited
  end

  f.resource "classes/pig", :class => Pig do |pig|
    pig.field :name, :visited
    pig.timeline :visions
  end

  f.resource "classes/pigkeeper", :class => Pigkeeper do |keeper|
    keeper.field :visited, :pockets
  end

  f.resource "classes/vision", :class => Vision do |vision|
    vision.field :text
    vision.reference :pig
  end

  f.resource "classes/message_board", :class => MessageBoard do |board|
    board.timeline :posts
  end

  f.resource "classes/post", :class => Post do |post|
    post.field :body
  end
end
