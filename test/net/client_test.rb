require 'test_helper'

class ClientTest < Minitest::Test
  attr_reader :subject

  def initialize(*args)
    super
    @subject = Net::Hippie::Client.new
    @subject.logger = Logger.new('/dev/null')
  end

  def test_get
    VCR.use_cassette('get_breaches') do
      uri = URI.parse('https://haveibeenpwned.com/api/breaches')
      response = subject.get(uri)
      refute_nil response
      assert_equal(283, JSON.parse(response.body).count)
    end
  end

  def test_get_with_retry
    uri = URI.parse('https://www.example.org/api/scim/v2/schemas')
    WebMock.stub_request(:get, uri.to_s)
      .to_timeout.then
      .to_timeout.then
      .to_return(status: 200, body: { 'success' => 'true' }.to_json)
    response = subject.with_retry(retries: 3) do |client|
      client.get(uri)
    end
    refute_nil response
    assert_equal response.class, Net::HTTPOK
    assert_equal('true', JSON.parse(response.body)['success'])
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

  def test_post_with_basic_auth_headers
    VCR.use_cassette('post_basic_auth') do
      uri = URI.parse('http://localhost:3000/oauth/tokens')
      client_id = "79a1c787-5cac-4cc5-b00e-374f5a909ef8"
      client_password = "za9NeRkm9YbqKDa6GreUmo6V"
      authorization_code = "NGooUnxYq5f5DHvJqyzDhSft"
      headers = { 'Authorization' => Net::Hippie.basic_auth(client_id, client_password) }
      body = { grant_type: 'authorization_code', code: authorization_code }
      response = subject.post(uri, headers: headers, body: body)
      refute_nil response
      json = JSON.parse(response.body, symbolize_names: true)
      assert_equal('Bearer', json[:token_type])
      assert(json[:token_type])
    end
  end

  def test_get_with_bearer_auth_headers
    VCR.use_cassette('get_bearer_auth') do
      uri = URI.parse('http://localhost:3000/oauth/me')
      token = "eyJhbGciOiJSUzI1NiJ9.eyJleHAiOjE1NDE4NzEyMDksImlhdCI6MTU0MTg2NzYwOSwiaXNzIjoiaHR0cDovL2xvY2FsaG9zdDo1MDAwL21ldGFkYXRhIiwibmJmIjoxNTQxODY3NjA5LCJhdWQiOiI3OWExYzc4Ny01Y2FjLTRjYzUtYjAwZS0zNzRmNWE5MDllZjgiLCJqdGkiOiIzZmZmODNkYi1mMmM3LTRjMDUtYWY4Zi02NWM5ODU1ODUyZjciLCJzdWIiOiIwNDJhZjE5Ny1hOTQxLTRkNTctYjc4Ny00M2IxYmNjZDUwNzAiLCJ0b2tlbl90eXBlIjoiYWNjZXNzIn0.HcwFAgg54RqKEONvHRigAavISuUUmkOA3gz0pkV6UEABCUHGucJCNehnvjpiwe4ZpCF_J6Uen6rfLFQOz7oYe416Du3_lQ3IS3Vc6hTpsT0XZ0bY-BVV_D9-thYFIrT7mNnNoxEs8AhOTBaAjgBammO_097MCwMjTGzAnxm1cmYfBad4yZPJ8HxDqeL769Urc6vz3Ku_M9yUzzfgb6jkwfFlvxmqHOPYWxlDY9uTR2uNr-ZYL5e6J6ZE8rgLkNRqy-jla03z2nFxEuxlSjYbBe60Vcwc4IyKS4QzbKXFXB1v9bKBvJxIUjQPQ7dICQeT9xSXQwDhnBtGUVcGM4njSH0-0rbxE470bGVslmYsChosX0PvRqlo4TMuVr7R5iuwWawZrIB-Dx3kkvhFYhn0jWrEEJkd96nLD-dmg2Tzqa40AE2WqmKtM5jM0LNO9E21l-hPQXAleoKspFIjT6Yd2Om4bJi-0eJB6sNqDuP55rvd5WSjp-ktrrtRirt-9aldCB_0eWP9oFCMJ_Xboq5w0P1W5MXlBv5p6eEdgRjohQyT-dkOvYsZiT9-Y5ggbBMhgtHm1CXZnutN0RE_skZk9PvxV_nUfTji3CHIaUhoJmeI11Tw2tdtOEt58RqkFgK7CZYylG7JqQS6eKpTLB2MrrZtCHY3rrrDaL64l6jYYQI"
      headers = { 'Authorization' => Net::Hippie.bearer_auth(token) }
      response = subject.get(uri, headers: headers)

      refute_nil response
      json = JSON.parse(response.body, symbolize_names: true)
      assert(json[:sub])
      assert(json[:exp])
      assert(json[:iss])
      assert(json[:nbf])
    end
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
