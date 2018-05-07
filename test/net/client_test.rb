require 'test_helper'

class Net::Hippie::ClientTest < Minitest::Test
  def test_get
    VCR.use_cassette("get_breaches") do
      headers = {
        'Accept' => 'application/vnd.haveibeenpwned.v2+json'
      }
      subject = Net::Hippie::Client.new(headers: headers)
      uri = URI.parse('https://haveibeenpwned.com/api/breaches')

      response = subject.get(uri)
      json =  JSON.parse(response.body)
      assert_equal(283, json.count)
      refute_nil response
    end
  end
end
