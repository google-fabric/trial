# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'fabric/trial/version'

Gem::Specification.new do |gem|
  gem.name          = "fabric-trial"
  gem.version       = Fabric::Trial::VERSION
  gem.authors       = ["Fabric Crashlytics"]
  gem.homepage      = "https://github.com/twitter-fabric/trial"
  gem.description   = %q{Allow easy attempting of new code paths with a safe fallback to the old}
  gem.summary       = %q{Attempt new code with a safety net}
  gem.licenses      = ['MIT']
  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(spec)/})
  gem.require_paths = ['lib']

  gem.add_development_dependency 'rake', '~> 10'
  gem.add_development_dependency 'rspec', '~> 3'
  gem.add_development_dependency 'pry', '~> 0'
end
