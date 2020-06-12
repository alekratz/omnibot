defmodule Omnibot.Module do
  defmacro __using__([]) do
    quote do
      use GenServer
      alias Omnibot.{Irc, Module}
      require Logger

      @behaviour Module

      ## Client API

      def start_link(opts) do
        GenServer.start_link(__MODULE__, opts[:cfg], opts ++ [name: __MODULE__])
      end

      def msg(msg), do: GenServer.cast(__MODULE__, msg)
      def msg(module, msg), do: GenServer.cast(module, {:msg, msg})

      ## Server callbacks

      @impl GenServer
      def init(cfg), do: {:ok, cfg}

      @impl Module
      def on_msg(msg) do
        route_msg(msg)
      end

      def route_msg(msg) do
        nick = msg.prefix.nick
        case String.upcase(msg.command) do
          "PRIVMSG" -> [channel | text] = msg.params
            on_channel_msg(channel, nick, Enum.join(text, " "))
          "JOIN" -> [channel | _] = msg.params
            on_join(channel, nick)
          "PART" -> [channel | _] = msg.params
            on_part(channel, nick)
          "KICK" -> [channel | _] = msg.params
            on_kick(channel, nick)
          _ -> nil
        end
      end

      @impl Module
      def on_channel_msg(_channel, _nick, _line), do: nil

      @impl Module
      def on_join(_channel, _nick), do: nil

      @impl Module
      def on_part(_channel, _nick), do: nil

      @impl Module
      def on_kick(_channel, _nick), do: nil

      @impl GenServer
      def handle_cast({:msg, msg}, cfg) do
        on_msg(msg)
        {:noreply, cfg}
      end

      defoverridable Module
      defoverridable GenServer
    end
  end

  @callback on_msg(msg :: %Omnibot.Irc.Msg{}) :: any
  @callback on_channel_msg(channel :: String.t, nick :: String.t, line :: String.t) :: any
  @callback on_join(channel :: String.t, nick :: String.t) :: any
  @callback on_part(channel :: String.t, nick :: String.t) :: any
  @callback on_kick(channel :: String.t, nick :: String.t) :: any
end
