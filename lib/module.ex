defmodule Omnibot.Module do
  defmodule Hooks do
    defmacro __before_compile__(_env) do
      quote do
        @impl true
        def on_channel_msg(_channel, _nick, _line), do: nil

        @impl true
        def on_channel_msg(_channel, _nick, _cmd, _params), do: nil

        @impl true
        def on_join(_channel, _nick), do: nil

        @impl true
        def on_part(_channel, _nick), do: nil

        @impl true
        def on_kick(_channel, _nick), do: nil
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
        Agent.start_link(fn -> opts[:cfg] end, opts ++ [name: __MODULE__])
      end

      def cfg do
        Agent.get(__MODULE__, & &1)
      end

      @impl Module
      def on_msg(msg) do
        # TODO - instead of using a router for modules, consider using a PubSub with a Registry:
        # https://hexdocs.pm/elixir/master/Registry.html#module-using-as-a-pubsub
        route_msg(msg)
      end

      defp route_msg(msg) do
        nick = msg.prefix.nick

        case String.upcase(msg.command) do
          "PRIVMSG" ->
            [channel | params] = msg.params
            line = Enum.join(params, " ")

            case String.split(line, " ") do
              [cmd | params] -> on_channel_msg(channel, nick, cmd, params)
              _ -> on_channel_msg(channel, nick, line)
            end

          "JOIN" ->
            [channel | _] = msg.params
            on_join(channel, nick)

          "PART" ->
            [channel | _] = msg.params
            on_part(channel, nick)

          "KICK" ->
            [channel | _] = msg.params
            on_kick(channel, nick)

          _ ->
            nil
        end
      end

      defoverridable Module

      @before_compile Omnibot.Module.Hooks
    end
  end

  @callback on_msg(msg :: %Omnibot.Irc.Msg{}) :: any
  @callback on_channel_msg(channel :: String.t(), nick :: String.t(), line :: String.t()) :: any
  @callback on_channel_msg(
              channel :: String.t(),
              nick :: String.t(),
              cmd :: String.t(),
              params :: [String.t()]
            ) :: any
  @callback on_join(channel :: String.t(), nick :: String.t()) :: any
  @callback on_part(channel :: String.t(), nick :: String.t()) :: any
  @callback on_kick(channel :: String.t(), nick :: String.t()) :: any

  defmacro command(cmd, opts) do
    quote generated: true do
      @impl Omnibot.Module
      def on_channel_msg(var!(channel), var!(nick), unquote(cmd), var!(params)) do
        unquote(opts[:do])
      end
    end
  end

  defmacro command(cmd, params, opts) do
    params =
      Enum.map(
        IO.inspect(params),
        fn param ->
          case param do
            {_, _, _} -> quote(do: var!(unquote(param)))
            lit -> Macro.escape(lit)
          end
        end
      )

    quote generated: true do
      @impl Omnibot.Module
      def on_channel_msg(var!(channel), var!(nick), unquote(cmd), unquote(params)) do
        unquote(opts[:do])
      end
    end
  end
end
