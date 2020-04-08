# -*- encoding: utf-8 -*-
require File.expand_path('../lib/sidekiq/failures/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Marcelo Silveira"]
  gem.email         = ["marcelo@mhfs.com.br"]
  gem.description   = %q{Keep track of Sidekiq failed jobs}
  gem.summary       = %q{Keeps track of Sidekiq failed jobs and adds a tab to the Web UI to let you browse them. Makes use of Sidekiq's custom tabs and middleware chain.}
  gem.homepage      = "https://github.com/mhfs/sidekiq-failures/"
  gem.license       = "MIT"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "sidekiq-failures"
  gem.require_paths = ["lib"]
  gem.version       = Sidekiq::Failures::VERSION

  gem.add_dependency "sidekiq", ">= 4.0.0"

  # Redis 4.X is incompatible with Ruby < 2.3, but the Ruby version constraint
  # wasn't added until 4.1.2, meaning you can get an incompatible version of the
  # redis gem when running Ruby 2.2 without this constraint.
  if Gem::Version.new(RUBY_VERSION) < Gem::Version.new("2.3.0")
    gem.add_dependency "redis", "< 4.0"
  end

  gem.add_development_dependency "minitest"
  gem.add_development_dependency "rake"
  gem.add_development_dependency "rack-test"
  gem.add_development_dependency "sprockets"
  gem.add_development_dependency "sinatra"
end
