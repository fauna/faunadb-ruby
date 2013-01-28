class Fauna::User
  field :pockets
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
