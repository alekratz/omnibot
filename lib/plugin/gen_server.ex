defmodule Omnibot.Plugin.GenServer do
  defmacro __using__([]) do
    quote do
      use Omnibot.Plugin.Base
      use GenServer 

      def start_link(opts) do
        cfg = opts[:cfg]
        state = opts[:state]
        GenServer.start_link(__MODULE__, {cfg, state}, opts)
      end

      def cfg() do
        GenServer.call(__MODULE__, :cfg)
      end

      def state() do
        GenServer.call(__MODULE__, :state)
      end

      def update_state(update) do
        GenServer.cast(__MODULE__, {:state, update})
      end

      ## Server callbacks

      @impl GenServer
      def init({cfg, state}) do
        state = state || on_init(cfg)
        {:ok, {cfg, state}}
      end

      @impl GenServer
      def handle_call(:cfg, _from, {cfg, state}) do
        {:reply, cfg, {cfg, state}}
      end

      @impl GenServer
      def handle_call(:state, _from, {cfg, state}) do
        {:reply, state, {cfg, state}}
      end

      @impl GenServer
      def handle_cast({:state, update}, {cfg, state}) do
        {:noreply, {cfg, apply(update, [state])}}
      end
    end
  end
end

