# Sidekiq::Failures [![Build Status](https://secure.travis-ci.org/mhfs/sidekiq-failures.png)](http://travis-ci.org/mhfs/sidekiq-failures)

Keeps track of Sidekiq failed jobs and adds a tab to the Web UI to let you browse
them. Makes use of Sidekiq's custom tabs and middleware chain.

It mimics the way Resque keeps track of failures.

Note that each failed retry will create a new failed job. This might result in a
pretty big failures list. Think twice before using this project. In most cases
automatic retries allied to exception notifications will be enough.

## Important Note!

This is an ongoing, alpha level project. Be prepared that the API might change and bugs might occur.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'sidekiq-failures'
```

## Dependencies

Depends on Sidekiq >= 2.2.1

## Usage

Simply having the gem in your Gemfile should be enough.

Your failed jobs will be visible via a Failures tab in the Web UI.

## TODO and Limitations

* Skip failures of specific workers (or the opposite).
* Remove all failed jobs via Web UI.
* Trigger retry of specific failed jobs via Web UI.
* Deal with retries. Maybe just track a failure when there's no attempt left.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## License

Released under the MIT License. See the [LICENSE][license] file for further details.

[license]: https://github.com/mhfs/sidekiq-failures/blob/master/LICENSE
