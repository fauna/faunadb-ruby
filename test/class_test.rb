require File.expand_path('../test_helper', __FILE__)

class InstanceTest < MiniTest::Unit::TestCase

  def setup
    super
    @model = Pig.new
  end

  def test_class_name
    assert_equal 'classes/pigs', Pig.ref
  end

  def test_create
    pig = Pig.create :data => { :visited => true }
    assert_equal true, pig.data['visited']
    assert pig.persisted?
    assert pig.ref
  end

  def test_all
    pig = Pig.create
    assert Pig.all.page.include?(pig.ref)
  end

  def test_save
    pig = Pig.new
    pig.save
    assert pig.persisted?
  end

  def test_update
    pig = Pig.new :data => { :visited => false }
    pig.save
    pig.update :data => { :visited => true }

    assert pig.data['visited']
    assert_equal pig.events.length, 2
  end

  def test_find
    pig = Pig.create
    pig1 = Pig.find(pig.ref)
    assert_equal pig.ref, pig1.ref
    assert pig1.persisted?
  end

  def test_find_by_constraint
    pig = Pig.create :constraints => { :name => "the pig" }
    pig1 = Pig.find_by_constraint("name", "the pig")
    assert_equal pig.ref, pig1.ref
    assert pig1.persisted?
  end

  def test_delete
    pig = Pig.create
    pig.delete
    assert pig.deleted?
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

    Fauna::Client.context(@server_connection) do
      pig2 = Pig.find(pig.ref)
      assert(time != pig2.ts)
    end

    pig.save

    Fauna::Client.context(@server_connection) do
      pig3 = Pig.find(pig.ref)
      # Waiting on server support for timestamp overrides
      # assert_equal time, pig3.ts
    end
  end
end
