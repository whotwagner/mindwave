# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'mindwave/version'

Gem::Specification.new do |spec|
  spec.name          = "mindwave"
  spec.version       = Mindwave::VERSION
  spec.authors       = ["Wolfgang Hotwagner"]
  spec.email         = ["code@feedyourhead.at"]

  spec.summary       = "mindwave is a ruby-implementation for Neurosky's Mindwave Headset"
  spec.description   = "This project communicates with the Mindwave Headset. "
  spec.homepage      = "https://tech.feedyourhead.at"
  spec.licenses      = ["GPL"]

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.12"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
