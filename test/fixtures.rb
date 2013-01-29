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
  field :pronouncement
  reference :pig
end

class MessageBoard < Fauna::Class
end

class Post < Fauna::Class
  field :body
end

Fauna.schema do |f|
  with Pig, :class_name => "classes/pigs" do
    timeline :visions
  end

  with Pigkeeper

  with Vision

  with MessageBoard, :class_name => "classes/board" do
    timeline :posts
  end

  with Post
end
