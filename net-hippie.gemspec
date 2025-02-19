# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'net/hippie/version'

Gem::Specification.new do |spec|
  spec.name          = 'net-hippie'
  spec.version       = Net::Hippie::VERSION
  spec.authors       = ['mo']
  spec.email         = ['mo@mokhan.ca']

  spec.summary       = 'net/http for hippies. ☮️ '
  spec.description   = 'net/http for hippies. ☮️ '
  spec.homepage      = 'https://rubygems.org/gems/net-hippie'
  spec.license       = 'MIT'
  spec.metadata      = {
    'source_code_uri' => 'https://github.com/xlgmokha/net-hippie',
    'rubygems_mfa_required' => 'true'
  }

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']
  spec.required_ruby_version = Gem::Requirement.new('>= 2.5.0')

  spec.add_dependency 'base64', '~> 0.1'
  spec.add_dependency 'json', '~> 2.0'
  spec.add_dependency 'logger', '~> 1.0'
  spec.add_dependency 'net-http', '~> 0.6'
  spec.add_dependency 'openssl', '~> 3.0'
  spec.add_development_dependency 'minitest', '~> 5.0'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rubocop', '~> 1.9'
  spec.add_development_dependency 'vcr', '~> 6.0'
  spec.add_development_dependency 'webmock', '~> 3.4'
end
