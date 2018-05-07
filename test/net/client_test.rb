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
end
