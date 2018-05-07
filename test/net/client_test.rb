require 'test_helper'

class Net::Hippie::ClientTest < Minitest::Test
  attr_reader :subject

  def initialize(*args)
    super
    @subject = Net::Hippie::Client.new(headers: {
      'Accept' => 'application/vnd.haveibeenpwned.v2+json'
    })
  end

  def test_get
    VCR.use_cassette("get_breaches") do
      uri = URI.parse('https://haveibeenpwned.com/api/breaches')
      response = subject.get(uri)
      refute_nil response
      assert_equal(283, JSON.parse(response.body).count)
    end
  end

  def test_get_with_block_syntax
    VCR.use_cassette("get_breaches") do
      uri = URI.parse('https://haveibeenpwned.com/api/breaches')
      subject.get(uri) do |request, response|
        @response = response
      end
      refute_nil @response
      assert_equal(283, JSON.parse(@response.body).count)
    end
  end

  def test_get_with_headers
    headers = { 'User-Agent' => 'example/agent' }
    WebMock.stub_request(:get, 'https://haveibeenpwned.com/api/breaches')
      .with(headers: headers)
      .to_return(status: 201, body: {}.to_json)

    uri = URI.parse('https://haveibeenpwned.com/api/breaches')

    response = subject.get(uri, headers: headers)
    refute_nil response
    assert_equal response.class, Net::HTTPCreated
  end

  def test_post
    VCR.use_cassette("post_breaches") do
      uri = URI.parse('https://haveibeenpwned.com/api/breaches')
      response = subject.post(uri)
      refute_nil response
      assert_equal "Congratulations!", JSON.parse(response.body)["Message"]
    end
  end

  def test_post_with_block_syntax
    VCR.use_cassette("post_breaches") do
      uri = URI.parse('https://haveibeenpwned.com/api/breaches')
      subject.post(uri) do |request, response|
        @response = response
      end
      refute_nil @response
      assert_equal "Congratulations!", JSON.parse(@response.body)["Message"]
    end
  end

  def test_put
    VCR.use_cassette("put_breaches") do
      uri = URI.parse('https://haveibeenpwned.com/api/breaches')
      body = { command: 'echo hello' }.to_json
      response = subject.put(uri, body: body)
      refute_nil response
      assert_equal "Congratulations!", JSON.parse(response.body)["Message"]
    end
  end

  def test_put_with_block_syntax
    VCR.use_cassette("put_breaches") do
      uri = URI.parse('https://haveibeenpwned.com/api/breaches')
      body = { command: 'echo hello' }.to_json
      subject.put(uri, body: body) do |request, response|
        @response = response
      end
      refute_nil @response
      assert_equal "Congratulations!", JSON.parse(@response.body)["Message"]
    end
  end
end
