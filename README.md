## KISSmetrics Threadsafe Ruby library

This gem is a threadsafe fork of the original `km` gem.

## `kmts` version 1.0.2

Version 1.0.2 of the `kmts` gem had an issue where it was found to not actually be thread safe. If you were using version 1.0.2 of the `kmts` gem, you were likely using non thread-safe code. In this case, you will want to either switch to using the non thread-safe [`km`](https://github.com/kissmetrics/km) gem, or update your code to use the thread-safe `kmts` gem version >= 2.0.0.

## Setup

The best way to install the gem is using `gem install kmts` or by adding it to your `Gemfile`:

```ruby
gem 'kmts', '~> 2.0.0'
```

Otherwise, the gem is available on GitHub:

https://github.com/kissmetrics/kmts

You will need your API key which you can find in your [site settings](http://support.kissmetrics.com/misc/site-settings).

## Usage

Before calling any of the common methods you **must** call `KMTS.init` with a valid API key:

```ruby
KMTS.init('KM_KEY' [, options])
```

The available options are:

* `log_dir`: sets the logging directory. Default is `'/tmp'`. Please make sure that the directory exists, and that whatever web process is writing to the log has permission to write to that directory. The log file will contain a list of the URLs that would be requested (`trk.kissmetrics.com` URLs - please refer to [API Specifications](http://support.kissmetrics.com/apis/specifications.html).
* `use_cron`: toggles whether to send data directly to KISSmetrics, or log to a file and send in the background via cron (see [Sending Data with Cron](http://support.kissmetrics.com/apis/cron) for more information). Default is `false`, which means data is sent directly to KISSmetrics. Using cron is optional, but **recommended**.
* `to_stderr`: allows toggling of printing output to `stderr`. Default is `true`.
* `dryrun`: New option as of November 25, 2012. Toggles whether to send data to KISSmetrics, or just log it to a file to review for debugging. Default is `false`, which means data is sent to KISSmetrics, regardless of whether you're working in a production or development environment.
* `env`: Updated option as of November 25, 2012. The environment variable now just helps us name the log files that store the history of event requests. This uses the Rails and Rack variables to determine if your Ruby environment is in `development`. If the Rails and Rack variables are not available, we default to `production`.

### Sample:

```ruby
KMTS.init("this is your key", :log_dir => '/var/logs/kissmetrics/')
```

### Sample (with SSL and timeouts)
```ruby
KMTS.init("this is your key", :log_dir       => File.join(Rails.root.to_s, 'log'),
							  :host          => "https://trk.kissmetrics.com:443",
							  :http_timeout  => 10
```

## Example Calls

**Note**: these calls use the newer syntax of the threadsafe gem. They are not compatible with the previous gem.

```ruby
KMTS.record('bob@bob.com', 'Viewed Homepage')
KMTS.record('bob@bob.com', 'Signed Up', {'Plan' => 'Pro', 'Amount' => 99.95})
KMTS.record('bob@bob.com', 'Signed Up', {'_d' => 1, '_t' => 1234567890})
KMTS.set('bob@bob.com', {:gender=>'male', 'Plan Name' => 'Pro'})
KMTS.alias('bob', 'bob@bob.com')
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
