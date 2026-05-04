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
  spec.description   = %q{Ruby client for the DIDWW JSON:API v3, covering DID inventory, voice in/out trunks, regulatory documents, exports, and emergency calling services.}
  spec.homepage      = 'https://github.com/didww/didww-v3-ruby'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 3.3'

  # Lower bounds match the oldest version verified by CI; upper bounds
  # cap on the next known-incompatible major so consumers get a clear
  # constraint failure rather than a runtime surprise. The CI matrix in
  # .github/workflows/tests.yml exercises activesupport ~> 7.2 / 8.0 /
  # 8.1 — declaring a wider lower bound than that would be aspirational.
  spec.add_dependency 'activesupport',     '>= 7.2', '< 9'
  spec.add_dependency 'faraday',           '~> 2.0'
  spec.add_dependency 'faraday-multipart', '~> 1.0'
  spec.add_dependency 'json_api_client',   '1.23.0'
  spec.add_dependency 'http',              '~> 5.0'
  spec.add_dependency 'down',              '~> 5.0'
  spec.add_dependency 'openssl-oaep',      '~> 0.1'
end
