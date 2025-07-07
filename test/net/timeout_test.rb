# frozen_string_literal: true

require 'test_helper'

class TimeoutTest < Minitest::Test
  def setup
    @uri = URI.parse('https://example.com/test')
  end

  def test_custom_read_timeout
    client = Net::Hippie::Client.new(read_timeout: 5)
    connection = client.send(:connection_for, @uri)
    backend = connection.instance_variable_get(:@backend)
    http = backend.instance_variable_get(:@http)
    assert_equal 5, http.read_timeout
  end

  def test_custom_open_timeout
    client = Net::Hippie::Client.new(open_timeout: 8)
    connection = client.send(:connection_for, @uri)
    backend = connection.instance_variable_get(:@backend)
    http = backend.instance_variable_get(:@http)
    assert_equal 8, http.open_timeout
  end

  def test_default_timeouts
    client = Net::Hippie::Client.new
    connection = client.send(:connection_for, @uri)
    backend = connection.instance_variable_get(:@backend)
    http = backend.instance_variable_get(:@http)
    assert_equal 10, http.read_timeout
    assert_equal 10, http.open_timeout
  end

  def test_read_timeout_triggers_retry
    WebMock.stub_request(:get, @uri.to_s)
           .to_timeout.then
           .to_return(status: 200, body: 'success')

    client = Net::Hippie::Client.new
    response = client.with_retry(retries: 1) { |c| c.get(@uri) }
    
    assert_equal Net::HTTPOK, response.class
    assert_equal 'success', response.body
  end

  def test_open_timeout_triggers_retry
    WebMock.stub_request(:get, @uri.to_s)
           .to_raise(Net::OpenTimeout).then
           .to_return(status: 200, body: 'success')

    client = Net::Hippie::Client.new
    response = client.with_retry(retries: 1) { |c| c.get(@uri) }
    
    assert_equal Net::HTTPOK, response.class
    assert_equal 'success', response.body
  end

  def test_timeout_with_zero_retries
    WebMock.stub_request(:get, @uri.to_s).to_timeout

    client = Net::Hippie::Client.new
    # WebMock.to_timeout raises different timeout errors, so check for any timeout error
    assert_raises(*Net::Hippie::CONNECTION_ERRORS.select { |e| e.name.include?('Timeout') }) do
      client.with_retry(retries: 0) { |c| c.get(@uri) }
    end
  end

  def test_multiple_timeout_types_in_sequence
    call_count = 0
    WebMock.stub_request(:get, @uri.to_s).to_return do
      call_count += 1
      case call_count
      when 1
        raise Net::OpenTimeout
      when 2
        raise Net::ReadTimeout
      when 3
        raise Timeout::Error
      else
        { status: 200, body: 'success' }
      end
    end

    client = Net::Hippie::Client.new
    response = client.with_retry(retries: 4) { |c| c.get(@uri) }
    
    assert_equal Net::HTTPOK, response.class
    assert_equal 'success', response.body
    assert_equal 4, call_count
  end

  def test_timeout_settings_per_connection
    uri1 = URI.parse('https://example1.com/test')
    uri2 = URI.parse('https://example2.com/test')

    client = Net::Hippie::Client.new(read_timeout: 15, open_timeout: 20)
    
    connection1 = client.send(:connection_for, uri1)
    connection2 = client.send(:connection_for, uri2)
    
    backend1 = connection1.instance_variable_get(:@backend)
    backend2 = connection2.instance_variable_get(:@backend)
    http1 = backend1.instance_variable_get(:@http)
    http2 = backend2.instance_variable_get(:@http)
    
    assert_equal 15, http1.read_timeout
    assert_equal 20, http1.open_timeout
    assert_equal 15, http2.read_timeout
    assert_equal 20, http2.open_timeout
  end

  def test_timeout_preserves_connection_pooling
    client = Net::Hippie::Client.new(read_timeout: 25)
    
    # First call should create connection
    connection1 = client.send(:connection_for, @uri)
    # Second call should reuse same connection
    connection2 = client.send(:connection_for, @uri)
    
    assert_same connection1, connection2
    
    backend = connection1.instance_variable_get(:@backend)
    http = backend.instance_variable_get(:@http)
    assert_equal 25, http.read_timeout
  end
end