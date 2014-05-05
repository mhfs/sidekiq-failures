## Unreleased

## 0.4.1
  * Restore compatibility for failed payloads created with 0.3.0
  * Ability to reset failed counter anyway, there are Failed jobs or not. (@davetoxa)
  * Fix sidekiq failures counter (@davetoxa)

## 0.4.0
  * Bump sidekiq dependency to sidekiq >= 2.16.0
  * Introduce delete(all) / retry(all) (@spectator)
  * Fix Sidekiq 3 compatibility (@petergoldstein)
  * Sidekiq 3 compatibility cleanup (@spectator)
  * Explicitly require sidekiq/api (@krasnoukhov)

## 0.3.0
  * Bump sidekiq dependency to sidekiq >= 2.14.0
  * Remove slim templates and dependecy
  * Escape exception info when outputing to html
  * Add `Sidekiq::Failures.reset_failures` helper method
  * Add `Sidekiq::Failures.count` helper method (@zanker)
  * Adhere to sidekiq approach of showing UTC times
  * Catch all exceptions, not just those that inherit from StandardError (@tylerkovacs)
  * Fix private method call (@bwthomas)

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
