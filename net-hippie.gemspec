# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'net/hippie/version'

Gem::Specification.new do |spec|
  spec.name          = 'net-hippie'
  spec.version       = Net::Hippie::VERSION
  spec.authors       = ['mo']
  spec.email         = ['mo@mokhan.ca']

  spec.summary       = 'net/http for hippies.'
  spec.description   = 'net/http for hippies.'
  spec.homepage      = 'https://www.mokhan.ca/'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.16'
  spec.add_development_dependency 'minitest', '~> 5.0'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rubocop', '~> 0.55'
  spec.add_development_dependency 'vcr', '~> 4.0'
  spec.add_development_dependency 'webmock', '~> 3.4'
end
