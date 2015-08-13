require File.expand_path('../test_helper', __FILE__)

class ClientTest < MiniTest::Unit::TestCase
  def setup
    super

    @test_ref = Fauna::Ref.new("classes/#{RandomHelper.random_string}/#{RandomHelper.random_number}")
    @test_set_match = RandomHelper.random_string
    @test_set_index = Fauna::Ref.new("indexes/#{RandomHelper.random_string}")
    @test_obj_key = RandomHelper.random_string
    @test_obj_value = RandomHelper.random_string

    @stubs.get('tests/ref') do
      [200, @test_headers, { 'resource' => @test_ref.to_hash }.to_json]
    end
    @stubs.get('tests/set') do
      [200, @test_headers, { 'resource' => Fauna::Set.new(@test_set_match, @test_set_index).to_hash }.to_json]
    end
    @stubs.get('tests/obj') do
      [200, @test_headers, { 'resource' => { '@obj' => { @test_obj_key => @test_obj_value } } }.to_json]
    end
  end

  def test_decode_ref
    response = @test_client.get('tests/ref')
    assert response.is_a?(Fauna::Ref)
    assert_equal @test_ref.value, response.value
  end

  def test_decode_set
    response = @test_client.get('tests/set')
    assert response.is_a?(Fauna::Set)
    assert_equal @test_set_match, response.match
    assert_equal @test_set_index.value, response.index.value
  end

  def test_decode_obj
    response = @test_client.get('tests/obj')
    assert response.is_a?(Hash)
    assert_equal @test_obj_value, response[@test_obj_key]
  end
end
