## KISSmetrics Threadsafe Ruby library

This gem is a threadsafe fork of the original `km` gem.

## Setup

The best way to install the gem is using `gem install kmts` or by adding it to your `Gemfile`:

```ruby
gem 'kmts', '>= 1.0.0'
```

Otherwise, the gem is available on GitHub:

https://github.com/kissmetrics/km/tree/threadsafe

You will need your API key which you can find in your [site settings](http://support.kissmetrics.com/misc/site-settings).

## Usage

Before calling any of the common methods you **must** call `KM.init` with a valid API key:

```ruby
KM.init('KM_KEY' [, options])
```

The available options are:

* `log_dir`: sets the logging directory. Default is `'/tmp'`. Please make sure that the directory exists, and that whatever web process is writing to the log has permission to write to that directory. The log file will contain a list of the URLs that would be requested (`trk.kissmetrics.com` URLs - please refer to [API Specifications](http://support.kissmetrics.com/apis/specifications.html).
* `use_cron`: toggles whether to send data directly to KISSmetrics, or log to a file and send in the background via cron (see [Sending Data with Cron](http://support.kissmetrics.com/apis/cron) for more information). Default is `false`, which means data is sent directly to KISSmetrics. Using cron is optional, but **recommended**.
* `to_stderr`: allows toggling of printing output to `stderr`. Default is `true`.
* `dryrun`: New option as of November 25, 2012. Toggles whether to send data to KISSmetrics, or just log it to a file to review for debugging. Default is `false`, which means data is sent to KISSmetrics, regardless of whether you're working in a production or development environment.
* `env`: Updated option as of November 25, 2012. The environment variable now just helps us name the log files that store the history of event requests. This uses the Rails and Rack variables to determine if your Ruby environment is in `development`. If the Rails and Rack variables are not available, we default to `production`.

### Sample:

```ruby
KM.init("this is your key", :log_dir => '/var/logs/kissmetrics/')
```

## Example Calls

**Note**: these calls use the newer syntax of the threadsafe gem. They are not compatible with the previous gem.

```ruby
KM.record('bob@bob.com', 'Viewed Homepage')
KM.record('bob@bob.com', 'Signed Up', {'Plan' => 'Pro', 'Amount' => 99.95})
KM.record('bob@bob.com', 'Signed Up', {'_d' => 1, '_t' => 1234567890})
KM.set('bob@bob.com', {:gender=>'male', 'Plan Name' => 'Pro'})
KM.alias('bob', 'bob@bob.com')
```

## Troubleshooting

If you were watching for the events in [KISSmetrics Live](http://support.kissmetrics.com/tools/live) and did not see them, it helps to review what our library logged. In the log directory, you may see these files:

* `kissmetrics_production_sent.log`
* `kissmetrics_production_query.log`
* `kissmetrics_production_error.log`
* `kissmetrics_development_sent.log`
* `kissmetrics_development_query.log`
* `kissmetrics_development_error.log`

If you contact support to troubleshoot, please refer to the contents of these files, if possible.
