defmodule Omnibot.Config do
  @moduledoc """
  The full configuration for an instance of Omnibot.

  This configuration structure contains both the IRC server connection information, along with all
  plugins and their configuration.

  ## Configuration keys

    - server: the IRC server to connect to. (required)
    - nick: the IRC nickname to use for the bot. (optional, default `"omnibot"`)
    - user: the IRC username to use for the bot. (optional, default `"omnibot"`)
    - real: the IRC realname to use for the bot. (optional, default `"omnibot"`)
    - port: the port to connect to the server on. (optional, default `6667`)
    - ssl: whether to use SSL or not. Note that IRC usually uses port 6697 for
           SSL. (optional, default `false`)
    - channels: a list of channels that the bot should always join. (optional, default `[]`)
    - plugins: a list of plugins to load and their configuration. (optional, default `[]`)
    - plugin_paths: a list of locations to look for additional plugins. (optional, default `[]`)

  ## Plugins configuration

  Inside the `plugins` key listed above, a list of plugins is expected. Plugins are either a single
  atom, or a tuple of the plugin and a keyword list of configuration.

  ### Plugin channels

  All plugins have a `channels` configuration value, determining which channels this plugin is
  active in. This value may also be set to the atom value `:all`, which indicates that it is active
  on all channels.

  At least one plugin in the configuration list must contain a list of channels, so that the bot
  knows which channels to join.

  ## Example configuration

  iex> %Omnibot.Config {
  ...>   nick: "omnibot_testing",
  ...>   server: "irc.bonerjamz.us",
  ...>   port: 6667,
  ...>   ssl: false,
  ...>   channels: ["#idleville"],
  ...>   plugins: [
  ...>     {Omnibot.Contrib.OnConnect, commands: [
  ...>       ["privmsg", "nickserv", "register", "password123", "omnibot@omni.bot"],
  ...>       ["privmsg", "nickserv", "identify", "password123"]
  ...>     ]},
  ...>     Omnibot.Contrib.Linkbot,
  ...>     Omnibot.Contrib.Fortune,
  ...>     {Omnibot.Contrib.Wordbot, ignore: ["username"]},
  ...>   ],
  ...>   plugin_paths: [{"plugins", recurse: true}]
  ...> }

  """

  alias Omnibot.Irc.Msg

  @enforce_keys [:server]
  defstruct [
    :server,
    nick: "omnibot",
    user: "omnibot",
    real: "omnibot",
    port: 6667,
    ssl: false,
    channels: [],
    plugins: [],
    plugin_paths: []
  ]

  @doc """
  Gets all channels that the bot should join via its plugins.

  ## Parameters

      - cfg: the configuration value to operate on.

  ## Examples

  iex> cfg = %Omnibot.Config {
  ...>     server: "irc.example.com",
  ...>     channels: ["#general"],
  ...>     plugins: [
  ...>       {ExamplePlugin, channels: ["#omnibot", "#example"]},
  ...>       {OtherPlugin, channels: ["#example"]}
  ...>     ]
  ...> }
  iex> Omnibot.Config.all_channels(cfg)
  ["#example", "#general", "#omnibot"]
  """
  def all_channels(cfg = %Omnibot.Config{}) do
    (do_all_channels(cfg.plugins) ++ cfg.channels)
    |> MapSet.new()
    |> MapSet.to_list()
  end

  defp do_all_channels([]) do
    []
  end

  defp do_all_channels([plugin | plugins]) when is_atom(plugin) do
    do_all_channels([{plugin, plugin.default_config()} | plugins])
  end

  defp do_all_channels([{_plugin, cfg} | plugins]) do
    channels = Keyword.get(cfg, :channels, [])
    head = if channels in [nil, :all],
      do: [],
      else: channels
    head ++ do_all_channels(plugins)
  end

  @doc """
  Creates an `Omnibot.Irc.Msg.Prefix` from this configuration to be sent to a server.

  ## Parameters

      - cfg: the configuration value to operate on.

  ## Examples

  iex> cfg = %Omnibot.Config { server: "irc.example.com" }
  iex> Omnibot.Config.msg_prefix(cfg)
  %Omnibot.Irc.Msg.Prefix {:nick => "omnibot", :user => "omnibot", :host => nil}
  """
  def msg_prefix(cfg = %Omnibot.Config{}) do
    %Msg.Prefix{
      nick: cfg.nick,
      user: cfg.user
    }
  end

  @doc """
  Make a new message with the given command and parameters using the given
  configuration to build the prefix.

  ## Parameters

      - cfg: the configuration value to operate on.
      - command: the IRC command to send
      - params: a list of parameters to pass to the IRC command.

  ## Examples

  iex> cfg = %Omnibot.Config { server: "irc.example.com" }
  iex> Omnibot.Config.msg(cfg, "PRIVMSG", ["#testing", "this is a test message"])
  %Omnibot.Irc.Msg{
    prefix: %Omnibot.Irc.Msg.Prefix {:nick => "omnibot", :user => "omnibot", :host => nil},
    command: "PRIVMSG",
    params: ["#testing", "this is a test message"],
  }
  """
  def msg(cfg = %Omnibot.Config{}, command, params \\ []) do
    %Msg{
      prefix: msg_prefix(cfg),
      command: command,
      params: params
    }
  end

  @doc """
  Gets all plugins that expect a message from the given config and channel.

  ## Parameters
  
      - cfg: the configuration that holds all plugins to search
      - channel: the channel to filter listening plugins on

  ## Example

  iex> cfg = %Omnibot.Config {
  ...>     server: "irc.example.com",
  ...>     channels: ["#general"],
  ...>     plugins: [
  ...>       {ExamplePlugin, channels: ["#omnibot", "#example"]},
  ...>       {OtherPlugin, channels: ["#example"]},
  ...>       {ThirdPlugin, channels: :all},
  ...>     ]
  ...> }
  iex> Omnibot.Config.channel_plugins(cfg, "#general")
  [{ThirdPlugin, channels: :all}]
  iex> Omnibot.Config.channel_plugins(cfg, "#omnibot")
  [{ExamplePlugin, channels: ["#omnibot", "#example"]}, {ThirdPlugin, channels: :all}]
  """
  def channel_plugins(cfg = %Omnibot.Config{}, channel) do
    do_channel_plugins(cfg.plugins, channel)
  end

  defp do_channel_plugins([], _channel), do: []

  defp do_channel_plugins([plugin | plugins], channel) when is_atom(plugin) do
    do_channel_plugins([{plugin, plugin.default_config()} | plugins], channel)
  end

  defp do_channel_plugins([{plugin, cfg} | plugins], channel) do
    plugin_channels = Keyword.get(cfg, :channels, [])
    head = if plugin_channels == :all || channel in plugin_channels,
      do: [{plugin, cfg}],
      else: []
    head ++ do_channel_plugins(plugins, channel)
  end

  @doc """
  Loads a configuration from a given path and an optional config binding.
  """
  def load(path, binding_name \\ :config) do
    with {_, bindings} <- Code.eval_file(path) do
      cfg = bindings[binding_name] 
      plugins = cfg.plugins
                |> Enum.map(fn
                  plug when is_atom(plug) -> {plug, plug.default_config()}
                  {plug, cfg}-> {plug, cfg ++ plug.default_config()}
                end)
         %Omnibot.Config{cfg | plugins: plugins}
    end
  end
end
