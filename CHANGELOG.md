## Unreleased
  * Allow per worker configuration of failure tracking mode. Thanks to
    @kbaum for most of the work.
  * Prevent sidekiq-failures from loading up sidekiq/processor (and thus
    Celluloid actors) except for inside a Sidekiq server context (@cheald)
  * Fix pagination bug
  * Add failures default mode option (@kbaum)

## 0.0.3

  * Adequate layout to new sidekiq web ui design (@krasnoukhov)
  * Improve backtrace view (@krasnoukhov)
  * Remove unnecessary slash in redirect (@krasnoukhov)
  * Invert order of failed jobs (@krasnoukhov)

## 0.0.2

  * Show backtrace similar to resque (Kunal Modi)
