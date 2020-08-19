# Omnibot

IRC bot with plugin/module support.

# Preparation

Omnibot is written in Elixir, which I am still learning. There are no releases yet, so there is no
"installation" process.

There are two ways to run omnibot: as a standalone process, or as a docker container.

## Standalone

### Requirements

* Elixir 1.10+
* A Rust compiler
    * You can install Rust via https://rustup.rs
    * I'm annoyed by this too. I'm working on getting rid of this dependency.

### Building

Run these lines to build:

```
mix local.hex
mix local.rebar3
mix deps.get
```

Confirm this by running `mix test`

## Docker

All you need for this is to be able to run `docker` and `docker-compose` - nothing else.

# Configuration

Runtime configuration is specified via an Elixir script, in **omnibot.exs** by default.  [An example
configuration](https://github.com/alekratz/omnibot/blob/master/omnibot.example.exs) is also provided
in the project root. Changing the configuration file can be done setting the environment variable
`OMNIBOT_CONFIG` to the path of the configuration file to use.

## Configuration keys

* `server` - the IRC server to connect to. **(required)**
* `nick` - the IRC nickname to use for the bot. **(optional, default "omnibot")**
* `user` - the IRC username to use for the bot. **(optional, default "omnibot")**
* `real` - the IRC realname to use for the bot. **(optional, default "omnibot")**
* `port` - the port to connect to the server on. **(optional, default 6667)**
* `ssl` - whether to use SSL or not. Note that IRC usually uses port 6697 for SSL. **(optional, default false)**
* `channels` - 
* `plugins` - a list of plugins to load and their configuration. **(optional, default [])**
* `plugin_paths` - a list of locations to look for additional plugins. **(optional, default [])**

### Plugin configuration

Plugin configuration is done as a list of either:

* a plugin name, e.g. `Core` or
* a *tuple* of plugin, and plugin configuration, e.g.
  `{Omnibot.Contrib.Fortune, channels: ["#general"]}`

#### Plugin channels

All plugins have a `channels` configuration value, which determines which IRC channels the plugin
will be active in. Alternatively, if you want a plugin to be active in all channels, you can specify
`channels: :all` in the plugin configuration instead of a list. This will also include channels
specified *only* in their channel config, which do not appear in the root-level "channels" config.
In other words, if "#foo" channel is joined only because it is specified by `SomePlugin`, all other
plugins that join `:all` will also be active in this channel. (author's note: this is probably not
desired behavior, but that's the behavior as of now)

## Gotchas

* In the configuration file, a `config` variable **must** be assigned to an `%Omnibot.Config {}`
  structure.
* The list of loaded plugins **must** include the `Core` plugin for correct functionality. This
  plugin handles things like joining channels and reconnecting to the server if the connection is
  lost.

# Usage

This section assumes that you have created a configuration file and are ready to run the bot.

## From standalone

Ensure you have your configuration saved in omnibot.exs (or wherever you decide to point it), and
then run:

`mix run --no-halt`

This will start the application up and running.

## Using Docker

Dockerfile, docker-compose.yml, and docker.env files have been provided so you can write your
omnibot.exs configuration and start a docker container. You should simply be able to run
`docker-compose up -d` and be good to go.

# Plugins

TODO: short intro about plugins and links to examples

# Final notes

Since this is a BEAM application, you will sometimes see error messages pop up. This is normal
behavior. If you see endless error messages (e.g. can't connect), then something is probably wrong
and checking the logs may help you determine the issue.

# License

AGPL-3.0-only

See LICENSE file for details.
