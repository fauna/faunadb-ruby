require File.expand_path('../test_helper', __FILE__)

class ClassTest < ActiveModel::TestCase
  include ActiveModel::Lint::Tests

  def setup
    super
    @model = Pig.new
  end

  def test_class_name
    assert_equal 'classes/pigs', Pig.fauna_class
    assert_equal 'classes/pigs/config', Pig.config_ref
  end

  def test_class_save
    Pig.update_data! do |data|
      data["class_visited"] = true
    end
    assert Pig.data["class_visited"]
  end

  def test_create
    pig = Pig.create(:visited => false)
    assert_equal false, pig.visited
    assert pig.persisted?
    assert pig.ref
  end

  def test_all
    pig = Pig.create
    assert Pig.all.resources.include?(pig)
  end

  def test_save
    pig = Pig.new
    pig.save
    assert pig.persisted?
  end

  def test_update
    pig = Pig.new(:visited => false)
    pig.save
    pig.update(:visited => true)
    assert pig.visited
  end

  def test_changes
    pig = Pig.new(:visited => true)
    pig.save
    pig.update(:visited => false)
    assert_equal pig.changes.page.events.length, 2
  end

  def test_find_by_ref
    pig = Pig.create
    pig1 = Pig.find_by_ref(pig.ref)
    assert_equal pig.ref, pig1.ref
    assert pig1.persisted?
  end

  def test_find_by_unique_id
    pig = Pig.create(:unique_id => "the pig")
    pig1 = Pig.find_by_unique_id("the pig")
    assert_equal pig.ref, pig1.ref
    assert pig1.persisted?
  end

  def test_find
    pig = Pig.create

    pig1 = Pig.find(pig.id)
    assert_equal pig.ref, pig1.ref
    assert pig1.persisted?

    pig2 = Pig.find_by_id(pig.id)
    assert_equal pig.ref, pig2.ref
    assert pig2.persisted?
  end

  def test_destroy
    pig = Pig.create
    pig.destroy
    assert pig.destroyed?
  end

  def test_ts
    pig = Pig.create
    assert_instance_of(Time, pig.ts)

    pig = Pig.new
    assert_nil pig.ts
  end

  def test_ts_assignment
    time = Time.at(0)
    pig = Pig.create
    pig.ts = time

    Fauna::Client.context(@publisher_connection) do
      pig2 = Pig.find(pig.id)
      assert_not_equal time, pig2.ts
    end

    pig.save

    Fauna::Client.context(@publisher_connection) do
      pig3 = Pig.find(pig.id)
      # Waiting on server support for timestamp overrides
      # assert_equal time, pig3.ts
    end
  end
end
