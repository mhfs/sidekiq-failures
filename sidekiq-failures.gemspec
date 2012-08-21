# -*- encoding: utf-8 -*-
require File.expand_path('../lib/sidekiq/failures/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Marcelo Silveira"]
  gem.email         = ["marcelo@mhfs.com.br"]
  gem.description   = %q{Keep track of Sidekiq failed jobs and add a tab to the Web UI to let you browse and manually retry them}
  gem.summary       = %q{Keep track of Sidekiq failed jobs and add a tab to the Web UI to let you browse and manually retry them}
  gem.homepage      = "https://github.com/mhfs/sidekiq-failures/"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "sidekiq-failures"
  gem.require_paths = ["lib"]
  gem.version       = Sidekiq::Failures::VERSION

  # FIXME uncomment once tab support is released
  # gem.add_dependency "sidekiq"
  gem.add_dependency "slim"
  gem.add_dependency "sinatra"
  gem.add_dependency "sprockets"

  gem.add_development_dependency "rake"
  gem.add_development_dependency "rack-test"
end
