defmodule Omnibot.Config do
  alias Omnibot.Irc.Msg

  @enforce_keys [:server]
  defstruct [
    :server,
    nick: "omnibot",
    user: "omnibot",
    real: "omnibot",
    port: 6667,
    ssl: false,
    modules: [],
    module_paths: []
  ]

  @doc ~S"""
  Gets all channels that the bot should join via its modules.
  """
  def all_channels(cfg) do
    Enum.flat_map(cfg.modules, fn
      {_, [channels: :all]} -> []
      {_, [channels: channels]} -> channels
    end)
      |> MapSet.new()
      |> MapSet.to_list()
  end

  def msg_prefix(cfg) do
    %Msg.Prefix {
      nick: cfg.nick,
      user: cfg.user,
    }
  end

  @doc ~S"""
  Make a new message with the given command and parameters using the given
  configuration to build the prefix.
  """
  def msg(cfg, command, params \\ []) do
    %Msg {
      prefix: msg_prefix(cfg),
      command: command,
      params: params,
    }
  end
end
