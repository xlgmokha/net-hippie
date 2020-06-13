$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'minitest/autorun'
require 'minitest/pride'
require 'minitest/spec'
require 'net/hippie'
require 'securerandom'
require 'vcr'
require 'webmock'

Net::Hippie.logger = ENV['CIBUILD'] ? Logger.new('/dev/null') : Logger.new(STDERR)

VCR.configure do |config|
  config.cassette_library_dir = 'test/fixtures'
  config.hook_into :webmock
end
