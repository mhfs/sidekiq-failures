# Sidekiq::Failures

Keeps track of Sidekiq failed jobs and adds a tab to the Web UI to let you browse
them. Makes use of Sidekiq's custom tabs and middlewares.

Note that each failed retry will create a new failed job. This might result in a
prety big failures list. Think twice before using this project. In most cases
automatic retries allied with exception notifications will be enough.

## Installation

Add this line to your application's Gemfile:

    gem 'sidekiq-failures'

And then execute:

    $ bundle

## Usage

Simply having the gem in your Gemfile should be enough.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
