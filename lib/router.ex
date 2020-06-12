defmodule Omnibot.Router do
  require Logger
  alias Omnibot.{Config, Irc, Irc.Msg, State}
  
  def route(irc, msg) do
    case String.upcase(msg.command) do
      "PRIVMSG" -> handle(irc, :privmsg, msg)
      "JOIN" -> handle(irc, :join, msg)
      "KICK" -> handle(irc, :kick, msg)
      "PART" -> handle(irc, :part, msg)
      "PING" -> handle(irc, :ping, msg)
      "001" -> handle(irc, :welcome, msg)
      _ -> nil
    end
  end

  def handle(_irc, :privmsg, msg) do
    # TODO : get channel, pass along to modules
    [channel | params] = msg.params
    line = Enum.join(params, " ")
    nick = msg.prefix.nick

    # Find modules that want this message
    State.cfg()
      |> Config.channel_modules(channel)
      |> Enum.each(fn {module, _} -> module.privmsg(module, channel, nick, line) end)
  end

  def handle(_irc, :join, %Msg {prefix: %Msg.Prefix{nick: nick}, params: [channel | _]}) do
    cfg = State.cfg()
    if nick == cfg.nick do
      State.add_channel(channel)
    end
  end

  def handle(irc, :kick, %Msg {params: [channel, who | _]}) do
    cfg = State.cfg()
    if who == cfg.nick do
      State.remove_channel(State, channel)
      # sync_channels here because this is a state that we (should) not have put ourselves into
      Irc.sync_channels(irc)
    end
  end

  def handle(_irc, :part, %Msg {prefix: %Msg.Prefix{nick: nick}, params: [channel | _]}) do
    cfg = State.cfg()
    if nick == cfg.nick do
      State.remove_channel(State, channel)
    end
  end

  def handle(irc, :ping, msg) do
    cfg = State.cfg()
    reply = Config.msg(cfg, "PONG", msg.params)
    Irc.send_msg(irc, reply)
  end

  def handle(irc, :welcome, _msg) do
    Irc.sync_channels(irc)
  end
end
