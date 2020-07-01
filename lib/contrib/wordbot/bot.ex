defmodule Omnibot.Contrib.Wordbot.Bot do
  use Omnibot.Module

  alias Omnibot.Contrib.Wordbot

  @split_pattern ~r/[\s\b]+/

  command "!wordbot", ["leaderboard"] do
    Irc.send_to(irc, channel, "leaderboard logic here")
  end

  @impl true
  def on_init(cfg) do
    Wordbot.Db.ensure_db()
    File.read!(cfg[:wordbot_source])
      |> String.split("\n")
  end

  @impl true
  def on_channel_msg(irc, channel, nick, msg) do
    words = Regex.split(@split_pattern, msg) |> MapSet.new()
    game_words = Wordbot.Db.unmatched_words(channel) |> MapSet.new()
    MapSet.intersection(words, game_words)
      |> Enum.each(fn word ->
        Wordbot.Db.add_score(channel, nick, word, msg)
        Irc.send_to(irc, channel, "#{nick}: Congrats! '#{word}' is good for 1 point.")
      end)
  end

  @impl true
  def on_join(_irc, _channel, _who) do
    # TODO start games
    # * Tasks for watching games(?)
  end
end
