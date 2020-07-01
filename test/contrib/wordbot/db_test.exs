defmodule WordbotDbTest do
  use ExUnit.Case

  alias Omnibot.Contrib.Wordbot

  setup do
    start_supervised!(Wordbot.Db.child_spec(":memory:"))
    Wordbot.Db.ensure_db()
    :ok
  end

  test "game starts round correctly" do
    :ok = Wordbot.Db.start_round("test", [], 60)
    assert Wordbot.Db.game_id!("test") == 1
    :ok = Wordbot.Db.start_round("foo", [], 60)
    assert Wordbot.Db.game_id!("foo") == 2

    {:error, :game_running} = Wordbot.Db.start_round("foo", [], 60)
    :ok = Wordbot.Db.start_round("foo", [], 60, end_early: true)
    assert Wordbot.Db.game_id!("foo") == 3
  end

  test "game keeps track of words" do
    :ok = Wordbot.Db.start_round("test", ~w(a b c d), 60)
    assert Wordbot.Db.words("test") == ~w(a b c d)

    :ok = Wordbot.Db.start_round("foo", ~w(e f g h), 60)
    assert Wordbot.Db.words("foo") == ~w(e f g h)
  end

  test "game keeps track of scores" do
    :ok = Wordbot.Db.start_round("test", ~w(a b c d), 60)
    Wordbot.Db.add_score("test", "user1", "a", "this is a line")
    Wordbot.Db.add_score("test", "user1", "b", "this is b line")
    Wordbot.Db.add_score("test", "user2", "c", "this is b line")
    
    scores = Wordbot.Db.scores("test")
    assert Enum.member?(scores, %{user: "user1", score: 2})
    assert Enum.member?(scores, %{user: "user2", score: 1})

    :ok = Wordbot.Db.start_round("test", ~w(a b c d), 60, end_early: true)
    scores = Wordbot.Db.scores("test")
    assert scores == []
  end

  test "game keeps track of unmatched words" do
    :ok = Wordbot.Db.start_round("test", ~w(a b c d), 60)
    assert Wordbot.Db.unmatched_words("test") == ~w(a b c d)
    Wordbot.Db.add_score("test", "user1", "a", "this is a line")
    Wordbot.Db.add_score("test", "user1", "b", "this is a line")
    Wordbot.Db.add_score("test", "user1", "d", "this is a line")
    assert Wordbot.Db.unmatched_words("test") == ~w(c)
  end
end
