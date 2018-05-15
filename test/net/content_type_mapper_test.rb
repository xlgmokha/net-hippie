require 'test_helper'

class ContentTypeMapperTest < Minitest::Test
  def test_returns_json
    subject = Net::Hippie::ContentTypeMapper.new
    headers = { 'Content-Type' => 'application/json' }
    body = { message: 'something witty' }
    result = subject.map_from(headers, body)
    assert_equal JSON.generate(body), result
  end

  def test_returns_json_with_charset
    subject = Net::Hippie::ContentTypeMapper.new
    headers = { 'Content-Type' => 'application/json; charset=utf-8' }
    body = { message: 'something witty' }
    result = subject.map_from(headers, body)
    assert_equal JSON.generate(body), result
  end

  def test_return_html
    subject = Net::Hippie::ContentTypeMapper.new
    headers = { 'Content-Type' => 'text/html' }
    body = '<html></html>'
    result = subject.map_from(headers, body)
    assert_equal body, result
  end
end
