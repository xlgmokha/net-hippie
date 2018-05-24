require 'test_helper'

class ClientTest < Minitest::Test
  attr_reader :subject

  def initialize(*args)
    super
    @subject = Net::Hippie::Client.new
  end

  def test_get
    VCR.use_cassette('get_breaches') do
      uri = URI.parse('https://haveibeenpwned.com/api/breaches')
      response = subject.get(uri)
      refute_nil response
      assert_equal(283, JSON.parse(response.body).count)
    end
  end

  def test_get_with_string_uri
    VCR.use_cassette('get_breaches') do
      response = subject.get('https://haveibeenpwned.com/api/breaches')
      refute_nil response
      assert_equal(283, JSON.parse(response.body).count)
    end
  end

  def test_get_with_generic_uri
    VCR.use_cassette('get_breaches') do
      uri = URI::Generic.build(host: 'haveibeenpwned.com', scheme: 'https', path: '/api/breaches', port: 443)
      response = subject.get(uri)
      refute_nil response
      assert_equal(283, JSON.parse(response.body).count)
    end
  end

  def test_get_with_block_syntax
    VCR.use_cassette('get_breaches') do
      uri = URI.parse('https://haveibeenpwned.com/api/breaches')
      subject.get(uri) do |_request, response|
        @response = response
      end
      refute_nil @response
      assert_equal(283, JSON.parse(@response.body).count)
    end
  end

  def test_get_with_headers
    headers = { 'Accept' => 'application/vnd.haveibeenpwned.v2+json' }
    WebMock.stub_request(:get, 'https://haveibeenpwned.com/api/breaches')
           .with(headers: headers)
           .to_return(status: 201, body: {}.to_json)

    uri = URI.parse('https://haveibeenpwned.com/api/breaches')

    response = subject.get(uri, headers: headers)
    refute_nil response
    assert_equal response.class, Net::HTTPCreated
  end

  def test_get_with_body
    uri = URI.parse('https://haveibeenpwned.com/api/breaches')
    body = { 'hello' => 'world' }
    WebMock.stub_request(:get, uri.to_s)
           .with(body: body.to_json)
           .to_return(status: 201, body: {}.to_json)

    response = subject.get(uri, body: body)

    refute_nil response
    assert_equal response.class, Net::HTTPCreated
  end

  def test_post
    VCR.use_cassette('post_breaches') do
      uri = URI.parse('https://haveibeenpwned.com/api/breaches')
      response = subject.post(uri)
      refute_nil response
      assert_equal 'Congratulations!', JSON.parse(response.body)['Message']
    end
  end

  def test_post_with_block_syntax
    VCR.use_cassette('post_breaches') do
      uri = URI.parse('https://haveibeenpwned.com/api/breaches')
      subject.post(uri) do |_request, response|
        @response = response
      end
      refute_nil @response
      assert_equal 'Congratulations!', JSON.parse(@response.body)['Message']
    end
  end

  def test_put
    VCR.use_cassette('put_breaches') do
      uri = URI.parse('https://haveibeenpwned.com/api/breaches')
      body = { command: 'echo hello' }.to_json
      response = subject.put(uri, body: body)
      refute_nil response
      assert_equal 'Congratulations!', JSON.parse(response.body)['Message']
    end
  end

  def test_put_with_block_syntax
    VCR.use_cassette('put_breaches') do
      uri = URI.parse('https://haveibeenpwned.com/api/breaches')
      body = { command: 'echo hello' }.to_json
      subject.put(uri, body: body) do |_request, response|
        @response = response
      end
      refute_nil @response
      assert_equal 'Congratulations!', JSON.parse(@response.body)['Message']
    end
  end

  def test_delete
    uri = URI.parse('https://haveibeenpwned.com/api/breaches')
    VCR.use_cassette('delete_breaches') do
      response = subject.delete(uri)
      refute_nil response
      assert_equal 'Congratulations!', JSON.parse(response.body)['Message']
    end
  end

  def test_client_tls
    private_key = OpenSSL::PKey::RSA.new(2048)
    certificate = OpenSSL::X509::Certificate.new
    certificate.not_after = certificate.not_before = Time.now
    certificate.public_key = private_key.public_key
    certificate.sign(private_key, OpenSSL::Digest::SHA256.new)

    subject = Net::Hippie::Client.new(certificate: certificate.to_pem, key: private_key.export)
    uri = URI.parse('https://haveibeenpwned.com/api/breaches')

    @called = false
    VCR.use_cassette('get_breaches') do
      subject.get(uri) do |_request, response|
        @called = true
        refute_nil response
        assert_equal '000webhost', JSON.parse(response.body)[0]['Title']
      end
    end
    assert(@called)
  end

  def test_client_tls_with_passphrase
    private_key = OpenSSL::PKey::RSA.new(2048)
    passphrase = SecureRandom.hex(16)
    certificate = OpenSSL::X509::Certificate.new
    certificate.not_after = certificate.not_before = Time.now
    certificate.public_key = private_key.public_key
    certificate.sign(private_key, OpenSSL::Digest::SHA256.new)

    subject = Net::Hippie::Client.new(
      certificate: certificate.to_pem,
      key: private_key.export(OpenSSL::Cipher.new('AES-256-CBC'), passphrase),
      passphrase: passphrase
    )
    uri = URI.parse('https://haveibeenpwned.com/api/breaches')

    @called = false
    VCR.use_cassette('get_breaches') do
      subject.get(uri) do |_request, response|
        @called = true
        refute_nil response
        assert_equal '000webhost', JSON.parse(response.body)[0]['Title']
      end
    end
    assert(@called)
  end
end
