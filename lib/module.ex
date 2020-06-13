defmodule Omnibot.Module do
  defmodule Hooks do
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
      end
    end
  end

  defmacro __using__([]) do
    quote do
      use Agent
      alias Omnibot.{Irc, Module}
      import Omnibot.Module
      require Logger

      @behaviour Module

      def start_link(opts) do
        cfg = opts[:cfg]
        Agent.start_link(fn -> {cfg, on_init(cfg)} end, opts ++ [name: __MODULE__])
      end

      def cfg do
        Agent.get(__MODULE__, fn {cfg, _} -> cfg end)
      end

      def state do
        Agent.get(__MODULE__, fn {_, state} -> state end)
      end

      def update_state(update, timeout \\ 5000) do
        Agent.update(
          __MODULE__,
          fn {cfg, state} -> {cfg, apply(update, [state])} end,
          timeout
        )
      end

      @impl Module
      def on_msg(irc, msg) do
        # TODO - instead of using a router for modules, consider using a PubSub with a Registry:
        # https://hexdocs.pm/elixir/master/Registry.html#module-using-as-a-pubsub
        route_msg(irc, msg)
      end

      defp route_msg(irc, msg) do
        nick = msg.prefix.nick

        case String.upcase(msg.command) do
          "PRIVMSG" ->
            [channel | params] = msg.params
            line = Enum.join(params, " ")

            case String.split(line, " ") do
              [cmd | params] -> on_channel_msg(irc, channel, nick, cmd, params)
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

      defoverridable Module

      @before_compile Omnibot.Module.Hooks
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

  defmacro command(cmd, opts) do
    quote generated: true do
      @impl Omnibot.Module
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
      @impl Omnibot.Module
      def on_channel_msg(var!(irc), var!(channel), var!(nick), unquote(cmd), unquote(params)) do
        unquote(opts[:do])
      end
    end
  end
end
