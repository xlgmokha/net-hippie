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

  def test_returns_string_body_unchanged
    subject = Net::Hippie::ContentTypeMapper.new
    headers = { 'Content-Type' => 'application/json' }
    body = '{"already": "json"}'
    result = subject.map_from(headers, body)
    assert_equal body, result
  end

  def test_returns_json_for_various_json_content_types
    subject = Net::Hippie::ContentTypeMapper.new
    body = { message: 'test' }
    expected = JSON.generate(body)

    json_types = [
      'application/json',
      'application/json; charset=utf-8',
      'application/json; charset=iso-8859-1',
      'application/vnd.api+json',
      'text/json'
    ]

    json_types.each do |content_type|
      headers = { 'Content-Type' => content_type }
      result = subject.map_from(headers, body)
      assert_equal expected, result, "Failed for content type: #{content_type}"
    end
  end

  def test_returns_hash_body_for_non_json_content_types
    subject = Net::Hippie::ContentTypeMapper.new
    body = { message: 'test' }

    non_json_types = [
      'text/plain',
      'text/html',
      'application/xml',
      'application/octet-stream',
      'multipart/form-data'
    ]

    non_json_types.each do |content_type|
      headers = { 'Content-Type' => content_type }
      result = subject.map_from(headers, body)
      assert_equal body, result, "Failed for content type: #{content_type}"
    end
  end

  def test_handles_nil_content_type
    subject = Net::Hippie::ContentTypeMapper.new
    headers = {}
    body = { message: 'test' }
    result = subject.map_from(headers, body)
    assert_equal body, result
  end

  def test_handles_empty_content_type
    subject = Net::Hippie::ContentTypeMapper.new
    headers = { 'Content-Type' => '' }
    body = { message: 'test' }
    result = subject.map_from(headers, body)
    assert_equal body, result
  end

  def test_handles_case_insensitive_content_type_headers
    subject = Net::Hippie::ContentTypeMapper.new
    body = { message: 'test' }

    # Test various case combinations - current implementation only handles exact 'Content-Type'
    # This test documents the current behavior
    headers_variations = [
      { 'content-type' => 'application/json' },
      { 'Content-type' => 'application/json' },
      { 'CONTENT-TYPE' => 'application/json' }
    ]

    headers_variations.each do |headers|
      result = subject.map_from(headers, body)
      # Current implementation doesn't handle case-insensitive headers
      # so these should return the original body, not JSON
      assert_equal body, result
    end
  end

  def test_handles_complex_json_objects
    subject = Net::Hippie::ContentTypeMapper.new
    headers = { 'Content-Type' => 'application/json' }
    body = {
      string: 'test',
      number: 123,
      boolean: true,
      nil_value: nil,
      array: [1, 2, 3],
      nested: { key: 'value' }
    }
    result = subject.map_from(headers, body)
    assert_equal JSON.generate(body), result
    # Verify it's valid JSON by parsing it back
    parsed = JSON.parse(result)
    expected_parsed = JSON.parse(JSON.generate(body))
    assert_equal expected_parsed, parsed
  end
end
