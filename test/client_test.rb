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
      [200, @test_headers, { 'response' => @test_ref.to_hash }.to_json]
    end
    @stubs.get('tests/set') do
      [200, @test_headers, { 'response' => Fauna::Set.new(@test_set_match, @test_set_index).to_hash }.to_json]
    end
    @stubs.get('tests/obj') do
      [200, @test_headers, { 'response' => { '@obj' => { @test_obj_key => @test_obj_value } }.to_hash }.to_json]
    end
  end

  def test_decode_ref
    response = Fauna::Client.new(@test_connection).get('tests/ref')
    assert response['response'].is_a?(Fauna::Ref)
    assert_equal @test_ref.ref, response['response'].ref
  end

  def test_decode_set
    response = Fauna::Client.new(@test_connection).get('tests/set')
    assert response['response'].is_a?(Fauna::Set)
    assert_equal @test_set_match, response['response'].match
    assert_equal @test_set_index.ref, response['response'].index.ref
  end

  def test_decode_obj
    response = Fauna::Client.new(@test_connection).get('tests/obj')
    assert response['response'].is_a?(Hash)
    assert_equal @test_obj_value, response['response'][@test_obj_key]
  end
end
