require File.expand_path('../../test_helper', __FILE__)

class FollowTest < ActiveModel::TestCase
  #include ActiveModel::Lint::Tests

  Fauna::Client.context(PUBLISHER_CONNECTION) do
    Pig.save!
    Pigkeeper.save!
  end

  def setup
    super
    @pig = Pig.create!
    @pigkeeper = Pigkeeper.create! :visited => true, :pockets => 1
    @attributes = {:follower => @pig, :resource => @pigkeeper}
    @model = Fauna::Follow.new(@attributes)
  end

  def test_create
    follow = Fauna::Follow.create(@attributes)
    assert follow.persisted?
    assert follow.ref
  end

  def test_save
    follow = Fauna::Follow.new(@attributes)
    follow.save
    assert follow.persisted?
    assert follow.ref
  end

  def test_update
    follow = Fauna::Follow.create(@attributes)
    assert_raises(Fauna::Invalid) do
      follow.update(@attributes)
    end
  end

  def test_find
    Fauna::Follow.create(@attributes)
    follow = Fauna::Follow.find_by_follower_and_resource(@pig, @pigkeeper)
    assert follow.persisted?
    assert follow.ref
  end

  def test_destroy
    follow = Fauna::Follow.create(@attributes)
    follow.destroy
    assert !follow.persisted?
    assert follow.ref
  end
end
