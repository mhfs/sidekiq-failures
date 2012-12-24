# Sidekiq::Failures [![Build Status](https://secure.travis-ci.org/mhfs/sidekiq-failures.png)](http://travis-ci.org/mhfs/sidekiq-failures)

Keeps track of Sidekiq failed jobs and adds a tab to the Web UI to let you browse
them. Makes use of Sidekiq's custom tabs and middleware chain.

It mimics the way Resque keeps track of failures.

TIP: Note that each failed job/retry might create a new failed job that will
only be removed by you manually. This might result in a pretty big failures list
depending on how you configure failures tracking in your workers.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'sidekiq-failures'
```

## Dependencies

Depends on Sidekiq >= 2.2.1

## Usage and Modes

Simply having the gem in your Gemfile is enough to get you started. Your failed jobs will be visible via a Failures tab in the Web UI.

Sidekiq-failures offers three failures tracking options (per worker):

### all (default)

Tracks failures everytime a background job fails. This mean a job with 25 retries enabled might generate up to 25 failure entries. If the worker has retry disabled only one failure will be tracked.

This is the default behavior but can be made explicit with:

```ruby
class MyWorker
  include Sidekiq::Worker

  sidekiq_options :failures => true # or :all

  def perform; end
end
```

### exhausted

Only track failures if the job exhausts all its retries (or doesn't have retries enabled).

You can set this mode as follows:

```ruby
class MyWorker
  include Sidekiq::Worker

  sidekiq_options :failures => :exhausted

  def perform; end
end
```

### off

You can also completely turn off failures tracking for a given worker as follows:

```ruby
class MyWorker
  include Sidekiq::Worker

  sidekiq_options :failures => false # or :off

  def perform; end
end
```

### Change the default mode

You can also change the default of all your workers at once by setting the following server config:

```ruby
Sidekiq.configure_server do |config|
  config.failures_default_mode = :off
end
```

The valid modes are `:all`, `:exhausted`, `:off`, `true` or `false`.

## TODO

* Allow triggering retry of specific failed jobs via Web UI.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## License

Released under the MIT License. See the [LICENSE][license] file for further details.

[license]: https://github.com/mhfs/sidekiq-failures/blob/master/LICENSE
