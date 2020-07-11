defmodule Omnibot.Contrib.Fortune do
  use Omnibot.Plugin.GenServer

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

  command "!fortune", [to] do
    fortune = Enum.random(@fortunes)
    reply = "#{to}: #{fortune}"
    Irc.send_to(irc, channel, reply)
  end

  command "!fortune" do
    fortune = Enum.random(@fortunes)
    reply = "#{nick}: #{fortune}"
    Irc.send_to(irc, channel, reply)
  end
end
