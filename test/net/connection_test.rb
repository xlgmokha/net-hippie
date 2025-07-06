# frozen_string_literal: true

require 'test_helper'

class ConnectionTest < Minitest::Test
  def test_initialize_with_http_scheme
    connection = Net::Hippie::Connection.new('http', 'example.com', 80)
    backend = connection.instance_variable_get(:@backend)
    refute backend.instance_variable_get(:@http).use_ssl?
  end

  def test_initialize_with_https_scheme
    connection = Net::Hippie::Connection.new('https', 'example.com', 443)
    backend = connection.instance_variable_get(:@backend)
    assert backend.instance_variable_get(:@http).use_ssl?
  end

  def test_initialize_with_custom_timeouts
    options = { read_timeout: 30, open_timeout: 15 }
    connection = Net::Hippie::Connection.new('https', 'example.com', 443, options)
    backend = connection.instance_variable_get(:@backend)
    http = backend.instance_variable_get(:@http)
    assert_equal 30, http.read_timeout
    assert_equal 15, http.open_timeout
  end

  def test_initialize_with_custom_verify_mode
    options = { verify_mode: OpenSSL::SSL::VERIFY_NONE }
    connection = Net::Hippie::Connection.new('https', 'example.com', 443, options)
    backend = connection.instance_variable_get(:@backend)
    http = backend.instance_variable_get(:@http)
    assert_equal OpenSSL::SSL::VERIFY_NONE, http.verify_mode
  end

  def test_initialize_with_client_certificate
    private_key = OpenSSL::PKey::RSA.new(2048)
    certificate = OpenSSL::X509::Certificate.new
    certificate.not_after = certificate.not_before = Time.now
    certificate.public_key = private_key.public_key
    certificate.sign(private_key, OpenSSL::Digest::SHA256.new)

    options = {
      certificate: certificate.to_pem,
      key: private_key.export
    }
    connection = Net::Hippie::Connection.new('https', 'example.com', 443, options)
    backend = connection.instance_variable_get(:@backend)
    http = backend.instance_variable_get(:@http)
    assert_equal certificate.to_pem, http.cert.to_pem
    assert_equal private_key.export, http.key.export
  end

  def test_initialize_with_client_certificate_and_passphrase
    private_key = OpenSSL::PKey::RSA.new(2048)
    passphrase = 'test_passphrase'
    certificate = OpenSSL::X509::Certificate.new
    certificate.not_after = certificate.not_before = Time.now
    certificate.public_key = private_key.public_key
    certificate.sign(private_key, OpenSSL::Digest::SHA256.new)

    options = {
      certificate: certificate.to_pem,
      key: private_key.export(OpenSSL::Cipher.new('AES-256-CBC'), passphrase),
      passphrase: passphrase
    }
    connection = Net::Hippie::Connection.new('https', 'example.com', 443, options)
    backend = connection.instance_variable_get(:@backend)
    http = backend.instance_variable_get(:@http)
    assert_equal certificate.to_pem, http.cert.to_pem
    assert_equal private_key.export, http.key.export
  end

  def test_run_executes_request
    WebMock.stub_request(:get, 'https://example.com/test')
           .to_return(status: 200, body: 'success')

    connection = Net::Hippie::Connection.new('https', 'example.com', 443)
    request = Net::HTTP::Get.new('/test')
    response = connection.run(request)

    assert_equal Net::HTTPOK, response.class
    assert_equal 'success', response.body
  end

  def test_build_url_for_absolute_path
    connection = Net::Hippie::Connection.new('https', 'example.com', 443)
    url = connection.build_url_for('https://other.com/path')
    assert_equal 'https://other.com/path', url
  end

  def test_build_url_for_relative_path_https
    connection = Net::Hippie::Connection.new('https', 'example.com', 443)
    url = connection.build_url_for('/api/v1/users')
    assert_equal 'https://example.com/api/v1/users', url
  end

  def test_build_url_for_relative_path_http
    connection = Net::Hippie::Connection.new('http', 'example.com', 80)
    url = connection.build_url_for('/api/v1/users')
    assert_equal 'http://example.com/api/v1/users', url
  end

  def test_build_url_for_http_url
    connection = Net::Hippie::Connection.new('https', 'example.com', 443)
    url = connection.build_url_for('http://other.com/path')
    assert_equal 'http://other.com/path', url
  end
end