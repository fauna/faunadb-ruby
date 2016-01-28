require File.expand_path('../test_helper', __FILE__)

class ClientLoggerTest < FaunaTest
  def setup
    super
    @class_ref = client.post(:classes, name: :logging_tests)[:ref]
  end

  def test_logging
    logged = capture_logged &:ping
    lines = logged.split "\n"
    read_line = lambda do
      lines.shift
    end

    assert_equal 'Fauna GET /ping', read_line.call
    assert_match(/^  Credentials:/, read_line.call)
    assert_equal '  Response headers: {', read_line.call
    # Skip through headers
    loop do
      line = read_line.call
      unless line.start_with? '    '
        assert_equal '  }', line
        break
      end
    end
    assert_equal '  Response JSON: {', read_line.call
    assert_equal '    "resource": "Scope global is OK"', read_line.call
    assert_equal '  }', read_line.call
    assert_match(/^  Response \(200\): Network latency \d+ms$/, read_line.call)
  end

  def test_request_content
    logged = capture_logged do |client|
      client.post @class_ref, data: {}
    end

    lines = logged.split "\n"
    read_line = lambda do
      lines.shift
    end

    assert_equal 'Fauna POST /classes/logging_tests', read_line.call
    assert_match(/^  Credentials:/, read_line.call)
    assert_equal '  Request JSON: {', read_line.call
    assert_equal '    "data": {', read_line.call
    close_data = read_line.call
    if close_data == '  '
      # Normally `JSON.pretty_generate({})` is "{\n}", but in JRuby it's "{\n\n}".
      # Accomadate both forms by checking for an (indented) empty line and skipping it.
      close_data = read_line.call
    end
    assert_equal '    }', close_data
    assert_equal '  }', read_line.call
    # Ignore the rest
  end

  def test_url_query
    instance = client.post @class_ref, data: {}
    logged = capture_logged do |client|
      client.get instance[:ref], ts: instance[:ts]
    end
    assert_equal "Fauna GET /#{instance[:ref]}?ts=#{instance[:ts]}", logged.split("\n")[0]
  end

private

  def capture_logged
    logged = nil
    client = get_client observer: (ClientLogger.logger do |logged_|
      logged = logged_
    end)
    yield client
    logged
  end
end
