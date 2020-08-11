defmodule Omnibot.Contrib.Wordbot do
  use Omnibot.Plugin
  alias Omnibot.{Contrib.Wordbot, Irc, Util}
  require Logger

  @default_config wordbot_source: "words.txt", wordbot_db: "wordbot.db", words_per_round: 300, hours_per_round: 5, ignore: []

  @impl true
  def children(cfg) do
    [
      {Task.Supervisor, name: Omnibot.Contrib.Wordbot.Watchers, strategy: :one_for_one},
      Wordbot.Db.child_spec(cfg[:wordbot_db]),
    ]
  end

  @split_pattern ~r/[\s\b]+/

  ## Bot commands

  command "!wordbot", ["leaderboard"] do
    Wordbot.Db.leaderboard(channel)
    |> Enum.sort_by(& &1.score)
    |> Enum.reverse()
    |> Enum.take(5)
    |> Enum.with_index()
    |> Enum.map(fn {%{user: nick, score: score}, rank} -> "#{rank + 1}. #{Util.denotify_nick(nick)}. #{score}" end)
    |> Enum.each(&Irc.send_to(irc, channel, &1))
  end

  ## Client API

  def words() do
    {words, _watchers} = state()
    words
  end

  defp watchers() do
    {_words, watchers} = state()
    watchers
  end

  defp update_watchers(mapping) do
    update_state(fn {words, watchers} -> {words, apply(mapping, [watchers])} end)
  end

  defp add_watcher(channel, task) do
    update_watchers(&Map.put(&1, channel, task))
  end

  defp delete_watcher(channel) do
    task = watchers()[channel]
    update_watchers(&Map.delete(&1, channel))
    task
  end

  defp lookup_watcher(channel) do
    Map.get(watchers(), channel)
  end

  defp has_watcher?(channel) do
    case lookup_watcher(channel) do
      nil -> false
      task -> Process.alive?(task)
    end
  end

  def start_round(irc, channel) do
    # Get round config
    cfg = cfg()
    num_words = cfg[:words_per_round]
    duration = cfg[:hours_per_round] * 3600
    # Select words
    words = Enum.take_random(words(), num_words)
    # Try to start the round - if it's already running then that's OK
    case Wordbot.Db.start_round(channel, words, duration) do
      :ok -> Logger.debug("Started new wordbot round for #{channel}")
      {:error, :game_running} -> Logger.debug("Wordbot game already running for #{channel}")
    end

    # Try to start a watcher if there isn't one running
    if !has_watcher?(channel),
      do: start_watcher(irc, channel)
  end

  defp start_watcher(irc, channel) do
    # Start a watcher for the given channel
    Logger.debug("Starting wordbot game watcher for #{channel}")
    # Assert that there isn't a running watcher for the current channel
    false = has_watcher?(channel)
    task = Task.Supervisor.async_nolink(
      Wordbot.Watchers,
      fn -> watch_game(irc, channel) end,
      [shutdown: :brutal_kill]
    )
    add_watcher(channel, task)
  end

  defp watch_game(irc, channel) do
    # Poll every second to check if a game is finished
    if Wordbot.Db.game_active?(channel) do
      Process.sleep(1000)
      watch_game(irc, channel)
    else
      finish_round(irc, channel)
    end
  end

  def finish_round(irc, channel) do
    Logger.debug("Finishing wordbot round for #{channel}")
    
    # Announce scores
    Irc.send_to(irc, channel, "Game over. Here were the scores:")
    scores = Wordbot.Db.scores(channel)
      |> Enum.sort_by(&(&1.score))
      |> Enum.reverse()

    # Ranking is a little weird because we want to rank people so that having
    # the same score will give the same ranking, e.g.
    # 1. user1. 4
    # 2. user2. 3
    # 2. user3. 3
    # 3. user4. 1
    rankings = scores
               |> Enum.map(&(&1.score))
               |> Enum.sort()
               |> Enum.uniq()
               |> Enum.reverse()
               |> Enum.with_index()
               |> Map.new()
    
    Enum.each(scores, &Irc.send_to(irc, channel, "#{rankings[&1.score] + 1}. #{Util.denotify_nick(&1.user)}. #{&1.score}"))

    # Stop the watcher, start new round
    delete_watcher(channel)
    start_round(irc, channel)
  end

  ## Plugin callbacks

  @impl true
  def on_init(cfg) do
    Wordbot.Db.ensure_db()
    words = File.read!(cfg[:wordbot_source])
            |> String.split("\n")
    watchers = %{}
    {words, watchers}
  end

  @impl true
  def on_channel_msg(irc, channel, nick, msg) do
    if nick not in cfg()[:ignore] do
      words = Regex.split(@split_pattern, msg) |> MapSet.new()
      game_words = Wordbot.Db.unmatched_words(channel) |> MapSet.new()
      MapSet.intersection(words, game_words)
        |> Enum.each(fn word ->
          Wordbot.Db.add_score(channel, nick, word, msg)
          Irc.send_to(irc, channel, "#{nick}: Congrats! '#{word}' is good for 1 point.")
        end)
    end
  end

  @impl true
  def on_join(irc, channel, who) do
    # Attempt to start a new round
    cfg = Irc.cfg(irc)
    if cfg.nick == who do
      start_round(irc, channel)
    end
  end
end
