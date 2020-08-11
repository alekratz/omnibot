defmodule Omnibot.Contrib.Fortune do
  use Omnibot.Plugin

  @fortunes [
    "Reply hazy, try again",
    "Excellent Luck",
    "Good Luck",
    "Average Luck",
    "Bad Luck",
    "Good news will come to you by mail",
    "You will meet a dark handsome stranger",
    "Better not tell you now",
    "Outlook good",
    "Very Bad Luck",
    "Godly Luck",

    "Outlook bad",
    "Today will be a good day!",
    "Pack a raincoat",
    "Fair Luck",
    "Good weather for cocks",
    "Look towards the setting sun",
    #"It's been years",
    #"God I wish that were me",
    "bad!",
    "Love is in your future",
    "You were young and foolish then, you are old and foolish now.",
    "Delete your account",
    "Rest in piss",
    "What a horrible night to have a curse.",
    "Closed: WONTFIX",
    "You've got mail!",
    "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb",
    "AAAAAAAAAAAAAAAAAA",

    "´_ゝ`",
    "ﾀ━━━━━━(ﾟ∀ﾟ)━━━━━━ !!!!",

    "¯\_(ツ)_/¯",
    ":^)",

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
