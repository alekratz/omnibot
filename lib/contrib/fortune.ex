defmodule Omnibot.Contrib.Fortune do
  use Omnibot.Module

  @fortunes [
    "Reply hazy, try again",
    "Excellent Luck",
    "Good Luck",
    "Average Luck",
    "Bad Luck",
    "Good news will come to you by mail",
    "´_ゝ`",
    "ﾀ━━━━━━(ﾟ∀ﾟ)━━━━━━ !!!!",
    "You will meet a dark handsome stranger",
    "Better not tell you now",
    "Outlook good",
    "Very Bad Luck",
    "Godly Luck",
  ]

  ## Client API

  def privmsg(module, channel, nick, line) do
    GenServer.cast(module, {:privmsg, {channel, nick, line}})
  end

  ## Server callbacks

  @impl true
  def on_channel_msg(channel, nick, line) do
    if line == "!fortune" do
      fortune = Enum.random(@fortunes)
      reply = "#{nick}: #{fortune}"
      Irc.send_to(channel, reply)
    end
  end
end
