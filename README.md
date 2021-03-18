# Puma::ForkEval

Puma plugin to fork-eval Ruby code in a preloaded application process. Like [`spring`](https://github.com/rails/spring) for `production`!

This plugin allows you to fork Puma's preloaded Rack app to run arbitrary Ruby code, such as:

- Load an interactive console
- Run recurring scheduled tasks
- Spawn asynchronous job processors

Instead of booting a duplicate copy of your Rails application which can take a long time and waste precious memory,
forking from a Puma server's already-loaded process is fast and copy-on-write is memory-efficient.
The bigger and slower your Rails app, the more you will love using `fork_eval`!

## Built for Production

[`spring`](https://github.com/rails/spring) is built for development/test environments, loading automatically
in a self-contained background process when needed and rebooting the app whenever relevant files are changed.
This behavior is convenient for development but can be dangerous for production,
where code changes are less frequent, rebooting the app is carefully controlled,
and resource usage is heavily optimized.

`fork-eval` is built for production:
- No extra servers hogging precious memory- just one background thread listening on a Unix domain socket.
- No stale or inconsistent app versions to worry about- your code runs on the exact version loaded by Puma.
- No binstub generation, automatic background-server launches or other surprising behavior-
  just a simple, direct command to fork+eval Ruby code in a Puma-preloaded app.

## Installation

Add `puma-fork_eval` to your application's `Gemfile` and run `bundle install`:

```ruby
gem 'puma-fork_eval'
```

## Usage

Enable the `:fork_eval` plugin in your Puma config (e.g., `config/puma.rb`:

    plugin :fork_eval

While Puma is running, run `fork_eval` with any Ruby code/script you wish to run:

    fork_eval path/to/my/script.rb

    echo 'puts Puma.stats' | fork_eval

    fork_eval <<RUBY
    puts Puma.stats
    RUBY

    fork_eval -e 'ARGV.clear; require "irb"; IRB.start'

## Advanced configuration

### Different user running `puma` server

By default the socket path used to connect the `fork_eval` script to the Puma process
is in a directory only accessible to the current OS user ([`$XDG_RUNTIME_DIR`](https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html#variables)),
which means that the Puma server needs to run as the same user as the user running `fork_eval` to connect properly.
To run `fork_eval` across separate users, set `FORK_EVAL_SOCKET` environment variable to a different path accessible by both users.

### Multiple `puma` servers

Because the default socket path is static, multiple `puma` servers won't be able to start with the `fork_eval` plugin enabled.
To support multiple servers, set `FORK_EVAL_SOCKET` environment variable to a custom path (e.g., `$XDG_RUNTIME_DIR/fork_eval_2.sock`) when starting
the Puma server, and set the same custom environment variable when running the `fork_eval` command.

## Security

NOTE: the use of `eval` indicates some security risk.
Any user with access to the socket can run Ruby code
that can access a copy of Puma and the loaded application.

The default socket path is in a directory only accessible to the current OS user ([`$XDG_RUNTIME_DIR`](https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html#variables)).
Whether this is secure enough depends on your own environment and security requirements.

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/wjordan/puma-fork_eval.
