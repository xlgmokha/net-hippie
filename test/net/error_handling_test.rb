# frozen_string_literal: true

require 'test_helper'

class ErrorHandlingTest < Minitest::Test
  def setup
    @client = Net::Hippie::Client.new
    @uri = URI.parse('https://example.com/test')
  end

  def test_handles_eof_error
    WebMock.stub_request(:get, @uri.to_s).to_raise(EOFError)
    
    assert_raises EOFError do
      @client.with_retry(retries: 0) { |client| client.get(@uri) }
    end
  end

  def test_handles_connection_refused
    WebMock.stub_request(:get, @uri.to_s).to_raise(Errno::ECONNREFUSED)
    
    assert_raises Errno::ECONNREFUSED do
      @client.with_retry(retries: 0) { |client| client.get(@uri) }
    end
  end

  def test_handles_connection_reset
    WebMock.stub_request(:get, @uri.to_s).to_raise(Errno::ECONNRESET)
    
    assert_raises Errno::ECONNRESET do
      @client.with_retry(retries: 0) { |client| client.get(@uri) }
    end
  end

  def test_handles_host_unreachable
    WebMock.stub_request(:get, @uri.to_s).to_raise(Errno::EHOSTUNREACH)
    
    assert_raises Errno::EHOSTUNREACH do
      @client.with_retry(retries: 0) { |client| client.get(@uri) }
    end
  end

  def test_handles_invalid_argument
    WebMock.stub_request(:get, @uri.to_s).to_raise(Errno::EINVAL)
    
    assert_raises Errno::EINVAL do
      @client.with_retry(retries: 0) { |client| client.get(@uri) }
    end
  end

  def test_handles_net_open_timeout
    WebMock.stub_request(:get, @uri.to_s).to_raise(Net::OpenTimeout)
    
    assert_raises Net::OpenTimeout do
      @client.with_retry(retries: 0) { |client| client.get(@uri) }
    end
  end

  def test_handles_net_protocol_error
    WebMock.stub_request(:get, @uri.to_s).to_raise(Net::ProtocolError)
    
    assert_raises Net::ProtocolError do
      @client.with_retry(retries: 0) { |client| client.get(@uri) }
    end
  end

  def test_handles_net_read_timeout
    WebMock.stub_request(:get, @uri.to_s).to_raise(Net::ReadTimeout)
    
    assert_raises Net::ReadTimeout do
      @client.with_retry(retries: 0) { |client| client.get(@uri) }
    end
  end

  def test_handles_openssl_error
    WebMock.stub_request(:get, @uri.to_s).to_raise(OpenSSL::OpenSSLError)
    
    assert_raises OpenSSL::OpenSSLError do
      @client.with_retry(retries: 0) { |client| client.get(@uri) }
    end
  end

  def test_handles_ssl_error
    WebMock.stub_request(:get, @uri.to_s).to_raise(OpenSSL::SSL::SSLError)
    
    assert_raises OpenSSL::SSL::SSLError do
      @client.with_retry(retries: 0) { |client| client.get(@uri) }
    end
  end

  def test_handles_socket_error
    WebMock.stub_request(:get, @uri.to_s).to_raise(SocketError)
    
    assert_raises SocketError do
      @client.with_retry(retries: 0) { |client| client.get(@uri) }
    end
  end

  def test_handles_timeout_error
    WebMock.stub_request(:get, @uri.to_s).to_raise(Timeout::Error)
    
    assert_raises Timeout::Error do
      @client.with_retry(retries: 0) { |client| client.get(@uri) }
    end
  end

  def test_retry_with_exponential_backoff
    call_count = 0
    WebMock.stub_request(:get, @uri.to_s).to_return do
      call_count += 1
      if call_count < 3
        raise Net::ReadTimeout
      else
        { status: 200, body: 'success' }
      end
    end

    start_time = Time.now
    response = @client.with_retry(retries: 3) { |client| client.get(@uri) }
    end_time = Time.now

    assert_equal Net::HTTPOK, response.class
    assert_equal 'success', response.body
    assert_equal 3, call_count
    # Should have some delay due to exponential backoff
    assert_operator end_time - start_time, :>, 0.3
  end

  def test_retry_eventually_fails_after_max_retries
    WebMock.stub_request(:get, @uri.to_s).to_raise(Net::ReadTimeout)
    
    start_time = Time.now
    
    assert_raises Net::ReadTimeout do
      @client.with_retry(retries: 2) { |client| client.get(@uri) }
    end
    
    end_time = Time.now
    # Should have attempted 3 times (initial + 2 retries) with delays
    assert_operator end_time - start_time, :>, 0.3
  end

  def test_retry_with_nil_retries
    WebMock.stub_request(:get, @uri.to_s).to_raise(Net::ReadTimeout)
    
    assert_raises Net::ReadTimeout do
      @client.with_retry(retries: nil) { |client| client.get(@uri) }
    end
  end

  def test_retry_with_negative_retries
    WebMock.stub_request(:get, @uri.to_s).to_raise(Net::ReadTimeout)
    
    assert_raises Net::ReadTimeout do
      @client.with_retry(retries: -1) { |client| client.get(@uri) }
    end
  end

  def test_connection_errors_constant_includes_all_expected_errors
    expected_errors = [
      EOFError,
      Errno::ECONNREFUSED,
      Errno::ECONNRESET,
      Errno::ECONNRESET,  # Listed twice in original
      Errno::EHOSTUNREACH,
      Errno::EINVAL,
      Net::OpenTimeout,
      Net::ProtocolError,
      Net::ReadTimeout,
      OpenSSL::OpenSSLError,
      OpenSSL::SSL::SSLError,
      SocketError,
      Timeout::Error
    ]
    
    expected_errors.each do |error_class|
      assert_includes Net::Hippie::CONNECTION_ERRORS, error_class
    end
  end
end