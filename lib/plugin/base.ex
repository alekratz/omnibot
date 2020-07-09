defmodule Omnibot.Plugin.Base do
  defmacro __before_compile__(_env) do
    quote generated: true do
      @impl true
      def on_channel_msg(_irc, _channel, _nick, _line), do: nil

      @impl true
      def on_channel_msg(_irc, _channel, _nick, _cmd, _params), do: nil

      @impl true
      def on_join(_irc, _channel, _nick), do: nil

      @impl true
      def on_part(_irc, _channel, _nick), do: nil

      @impl true
      def on_kick(_irc, _channel, _nick, _target), do: nil

      @impl true
      def on_init(_cfg), do: nil

      @impl true
      def default_config(), do: @default_config

      def commands(), do: MapSet.to_list(@commands)
    end
  end

  defmacro __using__([]) do
    quote do
      alias Omnibot.{Irc, Plugin}
      import Omnibot.Plugin.Base

      @behaviour Plugin.Base

      @impl Plugin.Base
      def on_msg(irc, msg) do
        route_msg(irc, msg)
      end

      defp route_msg(irc, %Irc.Msg {prefix: nil}), do: nil

      defp route_msg(irc, msg) do
        nick = msg.prefix.nick
        case String.upcase(msg.command) do
          "PRIVMSG" ->
            [channel | params] = msg.params
            line = Enum.join(params, " ")

            case String.split(line, " ") do
              [cmd | params] -> if Enum.member?(commands(), cmd),
                  do: on_channel_msg(irc, channel, nick, cmd, params),
                  else: on_channel_msg(irc, channel, nick, line)
              _ -> on_channel_msg(irc, channel, nick, line)
            end

          "JOIN" ->
            [channel | _] = msg.params
            on_join(irc, channel, nick)

          "PART" ->
            [channel | _] = msg.params
            on_part(irc, channel, nick)

          "KICK" ->
            [channel, target | _] = msg.params
            on_kick(irc, channel, nick, target)

          _ ->
            nil
        end
      end

      defoverridable Plugin.Base

      @commands MapSet.new()
      @default_config []
      @before_compile Omnibot.Plugin.Base
    end
  end

  @callback on_msg(irc :: pid(), msg :: %Omnibot.Irc.Msg{}) :: any
  @callback on_channel_msg(irc :: pid(), channel :: String.t(), nick :: String.t(), line :: String.t()) :: any
  @callback on_channel_msg(
              irc :: pid(),
              channel :: String.t(),
              nick :: String.t(),
              cmd :: String.t(),
              params :: [String.t()]
            ) :: any
  @callback on_join(irc :: pid(), channel :: String.t(), nick :: String.t()) :: any
  @callback on_part(irc :: pid(), channel :: String.t(), nick :: String.t()) :: any
  @callback on_kick(irc :: pid(), channel :: String.t(), nick :: String.t(), target :: String.t()) :: any
  @callback on_init(cfg :: any) :: any
  @callback default_config() :: any

  defmacro command(cmd, opts) do
    quote generated: true do
      @commands MapSet.put(@commands, unquote(cmd))
      @impl Omnibot.Plugin.Base
      def on_channel_msg(var!(irc), var!(channel), var!(nick), unquote(cmd), var!(params)) do
        unquote(opts[:do])
      end
    end
  end

  defmacro command(cmd, params, opts) do
    params =
      Enum.map(
        params,
        fn param ->
          case param do
            {_, _, _} -> quote(do: var!(unquote(param)))
            lit -> Macro.escape(lit)
          end
        end
      )

    quote generated: true do
      @commands MapSet.put(@commands, unquote(cmd))
      @impl Omnibot.Plugin.Base
      def on_channel_msg(var!(irc), var!(channel), var!(nick), unquote(cmd), unquote(params)) do
        unquote(opts[:do])
      end
    end
  end
end
