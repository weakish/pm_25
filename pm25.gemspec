# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'pm25/version'

Gem::Specification.new do |spec|
  spec.name          = 'pm25'
  spec.version       = PM25::VERSION
  spec.authors       = ['Jakukyo Friel']
  spec.email         = ['weakish@gmail.com']
  spec.summary       = %q{Fetch PM 2.5 data in China.}
  spec.description   = %q{A Ruby wrapper for pm25.in API and other PM 2.5
related utility functions.}
  spec.homepage      = 'https://github.com/weakish/pm25'
  spec.license       = 'MIT'
  spec.metadata      = {
      'repository' => 'https://github.com/weakish/pm25.git',
      'documentation' => 'http://www.rubydoc.info/gems/pm25/',
      'issues' => 'https://github.com/weakish/pm25/issues/',
      'wiki' => 'https://github.com/weakish/wiki/'
  }

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'nokogiri', '~> 1.6'
  spec.add_runtime_dependency 'rest_client', '~> 1.8'
  spec.add_runtime_dependency 'time-lord', '~> 1.0'
  spec.add_development_dependency 'bundler', '~> 1.7'
  spec.add_development_dependency 'rake', '~> 10.0'
end
