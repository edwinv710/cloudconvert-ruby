# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cloud_convert/version'

Gem::Specification.new do |spec|
  spec.name          = "cloudconvert-ruby"
  spec.version       = CloudConvert::VERSION
  spec.authors       = ["Edwin Velasquez"]
  spec.email         = ["edwin.velasquez89@gmail.com"]

  spec.summary       = "Ruby wrapper for the Cloud Convert API"
  spec.description   = "cloudconver-ruby is a ruby wrapper for the Cloud Convert API"
  spec.homepage      = "http://github.com/edwinv710/cloudconvert-ruby/"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host', or
  # delete this section to allow pushing this gem to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "https://rubygems.org/"
  else
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "webmock", "~> 1.22.3"
  spec.add_development_dependency "sinatra", "~> 1.4.3"
  spec.add_development_dependency "vcr", "~> 3.0.0"
  spec.add_development_dependency "rake-notes"

  spec.add_dependency "httmultiparty", "~> 0.3.15"
end
