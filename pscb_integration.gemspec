# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'pscb_integration/version'

Gem::Specification.new do |spec|
  spec.name          = "pscb_integration"
  spec.version       = PscbIntegration::VERSION
  spec.authors       = ['Alex Emelyanov']
  spec.email         = ['holyketzer@gmail.com']

  spec.summary       = 'PSCB payment gateway integration'
  spec.description   = 'If you not sure, think a little about using of Yandex Kassa instead :)'
  spec.homepage      = 'https://github.com/holyketzer/pscb_integration'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end

  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency 'faraday', '~> 0.9.1'
  spec.add_dependency 'faraday_middleware', '~> 0.9'
  spec.add_dependency 'fear', '~> 0.5.0'
  spec.add_dependency 'rails', '~> 4.2'

  spec.add_development_dependency 'addressable', '~> 2.5'
  spec.add_development_dependency 'bundler', '~> 1.13'
  spec.add_development_dependency 'fear-rspec', '~> 0.2.0'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rspec-rails', '~> 3.0'
  spec.add_development_dependency 'sqlite3'
  spec.add_development_dependency 'vcr', '~> 2.9'
  spec.add_development_dependency 'webmock', '~> 1.17'
end
