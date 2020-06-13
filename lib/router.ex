defmodule Omnibot.Router do
  require Logger
  alias Omnibot.{Irc.Msg, State}
  
  def route(irc, msg) do
    channel = Msg.channel(msg)
    State.channel_modules(channel)
      |> Enum.each(fn {module, _} -> module.on_msg(irc, msg) end)
  end

  #def handle(_irc, :privmsg, msg) do
  #  [channel | _params] = msg.params

  #  # Find modules that want this message
  #  State.cfg()
  #    |> Config.channel_modules(channel)
  #    |> Enum.each(fn {module, _} -> module.on_msg(msg) end)
  #end

  #def handle(_irc, :join, msg: %Msg {params: [channel | _]}) do
  #  State.cfg()
  #    |> Config.channel_modules(channel)
  #    |> Enum.each(fn {module, _} -> module.on_join(msg) end)
  #end

  #def handle(irc, :kick, msg: %Msg {params: [channel | _]}) do
  #  State.cfg()
  #    |> Config.channel_modules(channel)
  #    |> Enum.each(fn {module, _} -> module.on_kick(msg) end)
  #end

  #def handle(_irc, :part, %Msg {prefix: %Msg.Prefix{nick: nick}, params: [channel | _]}) do
  #  cfg = State.cfg()
  #  if nick == cfg.nick do
  #    State.remove_channel(State, channel)
  #  end
  #end

  #def handle(irc, :ping, msg) do
  #  cfg = State.cfg()
  #  reply = Config.msg(cfg, "PONG", msg.params)
  #  Irc.send_msg(irc, reply)
  #end

  #def handle(irc, :welcome, _msg) do
  #  Irc.sync_channels(irc)
  #end
end
