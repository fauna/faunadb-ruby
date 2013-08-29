require File.expand_path('../test_helper', __FILE__)

class ClassTest < MiniTest::Unit::TestCase

  def setup
    super
    @model = Fauna::Resource.new('classes/pigs')
  end

  def test_create
    pig = Fauna::Resource.create 'classes/pigs', :data => { :visited => true }
    assert_equal true, pig.data['visited']
    assert pig.persisted?
    assert pig.ref
  end

  def test_all
    pig = Fauna::Resource.create 'classes/pigs'
    assert Fauna::Set.new('classes/pigs/instances').page.include?(pig.ref)
  end

  def test_save
    pig = Fauna::Resource.new 'classes/pigs'
    pig.save
    assert pig.persisted?
  end

  def test_update
    pig = Fauna::Resource.new 'classes/pigs', :data => { :visited => false }
    pig.save
    pig.data['visited'] = true
    pig.save

    assert pig.data['visited']
    assert_equal pig.events.length, 2
  end

  def test_find
    pig = Fauna::Resource.create 'classes/pigs'
    pig1 = Fauna::Resource.find(pig.ref)
    assert_equal pig.ref, pig1.ref
    assert pig1.persisted?
  end

  def test_delete
    pig = Fauna::Resource.create 'classes/pigs'
    pig.delete
    assert pig.deleted?
  end

  def test_ts
    pig = Fauna::Resource.create 'classes/pigs'
    assert_instance_of(Time, pig.ts)

    pig = Fauna::Resource.new 'classes/pigs'
    assert_nil pig.ts
  end

  def test_ts_assignment
    time = Time.at(0)
    pig = Fauna::Resource.create 'classes/pigs'
    pig.ts = time

    Fauna::Client.context(@server_connection) do
      pig2 = Fauna::Resource.find(pig.ref)
      assert(time != pig2.ts)
    end

    pig.save

    Fauna::Client.context(@server_connection) do
      pig3 = Fauna::Resource.find(pig.ref)
      # Waiting on server support for timestamp overrides
      # assert_equal time, pig3.ts
    end
  end
end
