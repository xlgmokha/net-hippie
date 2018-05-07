$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require "net/hippie"
require "vcr"
require "webmock"

require "minitest/autorun"

VCR.configure do |config|
  config.cassette_library_dir = "test/fixtures"
  config.hook_into :webmock
end
