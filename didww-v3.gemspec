# frozen_string_literal: true

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'didww/version'

Gem::Specification.new do |spec|
  spec.name          = 'didww-v3'
  spec.version       = DIDWW::VERSION
  spec.authors       = ['Alex Korobeinikov']
  spec.email         = ['alex.k@didww.com']

  spec.summary       = %q{Ruby client for DIDWW API v3}
  spec.description   = %q{Ruby client for DIDWW API v3}
  spec.homepage      = 'https://github.com/didww/didww-v3-ruby'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 3.3'

  spec.add_dependency 'activesupport'
  spec.add_dependency 'faraday'
  spec.add_dependency 'json_api_client', '1.23.0'
  spec.add_dependency 'http'
  spec.add_dependency 'down'
  spec.add_dependency 'openssl-oaep'
end
