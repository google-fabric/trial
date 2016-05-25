# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'trial/version'

Gem::Specification.new do |gem|
  gem.name          = "Trial"
  gem.version       = Trial::VERSION
  gem.authors       = ["Fabric Crash Metrics Team"]
  gem.email         = ['fabric-crash-metrics@twitter.com']
  gem.description   = %q{Allow easy attempting of new code paths with a safe fallback to the old}
  gem.summary       = %q{Attempt new code with a safety net}

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(spec)/})
  gem.require_paths = ['lib']

  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'rspec', '~> 3'
  gem.add_development_dependency 'pry'
end
