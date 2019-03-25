# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'lolsoap/version'

Gem::Specification.new do |spec|
  spec.name          = "lolsoap"
  spec.version       = LolSoap::VERSION
  spec.authors       = ["Jon Leighton"]
  spec.summary       = %q{A library for dealing with SOAP requests and responses.}
  spec.description   = %q{A library for dealing with SOAP requests and responses. We tear our hair out so you don't have to.}
  spec.homepage      = "http://github.com/loco2/lolsoap"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency 'nokogiri', '~> 1.5'

  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", "~> 12.3"
  spec.add_development_dependency "minitest", "~> 2.10.0"
  spec.add_development_dependency "yard"
end
