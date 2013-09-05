## Unreleased

## 0.2.2
  * Support ERB for sidekiq >= 2.14.0 (@tobiassvn)
  * Bump sidekiq dep to >= 2.9.0
  * Show newest failures first (@PlugIN73)
  * Fix specs (@krasnoukhov)

## 0.2.1
  * Fix exhausted mode when retry is disabled (@wr0ngway)

## 0.2.0
  * Added processor identity to failure data (@krasnoukhov)
  * Handle Sidekiq::Shutdown exceptions (@krasnoukhov)
  * Add failures maximum count option (@mathieulaporte)
  * User Expception#message instead of Exception#to_s (@supaspoida)
  * Removed web depencies (@LongMan)
  * Stop overloading find_template (@zquestz)

## 0.1.0
  * Allow per worker configuration of failure tracking mode. Thanks to
    @kbaum for most of the work.
  * Prevent sidekiq-failures from loading up sidekiq/processor (and thus
    Celluloid actors) except for inside a Sidekiq server context (@cheald)
  * Fix pagination bug
  * Add failures default mode option (@kbaum)
  * Add checkbox option to reset failed counter (@krasnoukhov)

## 0.0.3

  * Adequate layout to new sidekiq web ui design (@krasnoukhov)
  * Improve backtrace view (@krasnoukhov)
  * Remove unnecessary slash in redirect (@krasnoukhov)
  * Invert order of failed jobs (@krasnoukhov)

## 0.0.2

  * Show backtrace similar to resque (Kunal Modi)
