require 'test_helper'

class ApiTest < Minitest::Test
  def test_get
    VCR.use_cassette('get_breaches') do
      subject = Net::Hippie::Api.new('https://haveibeenpwned.com/api/breaches')
      response = subject.get
      refute_nil response
      assert_equal(283, JSON.parse(response).count)
    end
  end

  def test_execute
    VCR.use_cassette('get_breaches') do
      subject = Net::Hippie::Api.new('https://haveibeenpwned.com/api/breaches')
      request = Net::HTTP::Get.new('https://haveibeenpwned.com/api/breaches')
      request['Range'] = 'bytes=0-511'
      response = subject.execute(request)
      refute_nil response
      assert_equal(283, JSON.parse(response.body).count)
    end
  end
end
