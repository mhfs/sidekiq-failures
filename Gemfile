source 'https://rubygems.org'

# Specify your gem's dependencies in sidekiq-failures.gemspec
gemspec

gem 'sidekiq', ENV['SIDEKIQ_VERSION'] if ENV['SIDEKIQ_VERSION']

# to test Pro-specific functionality, set SIDEKIQ_PRO_CREDS on `bundle install`
# and SIDEKIQ_PRO_VERSION on `bundle install` and `rake test`
source "https://#{ENV['SIDEKIQ_PRO_CREDS']}@enterprise.contribsys.com/" do    
    gem 'sidekiq-pro', ENV['SIDEKIQ_PRO_VERSION'] if ENV['SIDEKIQ_PRO_VERSION']
end if ENV['SIDEKIQ_PRO_VERSION']