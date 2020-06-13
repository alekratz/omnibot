defmodule Omnibot.Router do
  require Logger
  alias Omnibot.{Config, Irc, Irc.Msg, State}
  
  def route(irc, msg) do
    # TODO - consider removing this check and specific handling into the `use Omnibot.Module` block
    # PROS:
    # - Don't have to determine message command twice (first here, second in Omnibot.Module)
    # - Allows for much more powerful modules. JOIN, PART, KICK, etc handlers would be modules themselves
    #   - This is an extremely big win IMO
    #
    # CONS:
    # - All routed functionality needs to be in a module
    #   - This may get a little old
    # - A failed command could cause important messages to be missed (?)
    #   - Do messages in a named PID's mailbox persist after that PID goes away? My guess is "no"
    #   - To get around this, there could be a mailbox for "special" commands, probably using ETS
    # 
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
    [channel | _params] = msg.params

    # Find modules that want this message
    State.cfg()
      |> Config.channel_modules(channel)
      |> Enum.each(fn {module, _} -> module.on_msg(msg) end)
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
