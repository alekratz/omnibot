defmodule Omnibot.Contrib.Wordbot.Db do
  alias Omnibot.Util

  # SQL for creating the new database
  @database_sql ~S"""
  CREATE TABLE IF NOT EXISTS game (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      start INTEGER NOT NULL,
      end INTEGER NOT NULL,
      channel VARCHAR(40) NOT NULL
  );
  CREATE TABLE IF NOT EXISTS word (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      game INTEGER NOT NULL,
      word VARCHAR(40) NOT NULL,
      FOREIGN KEY (game) REFERENCES game(id),
      UNIQUE(game, word)
  );
  CREATE TABLE IF NOT EXISTS score (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      game INTEGER NOT NULL,
      word INTEGER NOT NULL,
      user VARCHAR(40) NOT NULL,
      line VARCHAR(1024) NOT NULL,
      FOREIGN KEY (game) REFERENCES game(id),
      FOREIGN KEY (word) REFERENCES word(id),
      UNIQUE(game, word)
  );
  """

  def ensure_db() do
    Sqlitex.Server.exec(__MODULE__, @database_sql)
  end

  @doc "Gets the words for the current round in the given channel."
  def words(channel) do
    id = game_id!(channel)
    {:ok, rows} =
      Sqlitex.Server.query(__MODULE__, "SELECT word FROM word WHERE game = ?1", bind: [id])

    for row <- rows, do: row[:word]
  end

  @doc """
  Starts a new round for the given channel in the database.

  ## Options

  * `:end_early` - if `true`, this will create a new game even though there is
    a game already running. Default is false.

  ## Returns

  * `:ok` if a new round was started.
  * `{:error, :game_running}` if a game couldn't be started because one was already running.
  """
  def start_round(channel, words, duration, opts \\ []) do
    end_early = Access.get(opts, :end_early, false)

    if !game_active?(channel) or end_early do
      start = Util.now_unix()
      end_ = start + duration

      with {:ok, _} <-
             Sqlitex.Server.query(
               __MODULE__,
               "INSERT INTO game (start, end, channel) VALUES (?1, ?2, ?3)",
               bind: [start, end_, channel]
             ),
           {:ok, game_id} = game_id(channel) do

        # Much faster to just prepare everything in one go rather than enumerating all words
        pattern = (0 .. length(words) - 1)
          |> Enum.map(&"(?1, ?#{&1 + 2})")
          |> Enum.join(", ")
        Sqlitex.Server.query(
          __MODULE__,
          "INSERT INTO word (game, word) VALUES #{pattern}",
          bind: [game_id | words]
        )
      end
      :ok
    else
      {:error, :game_running}
    end
  end

  def game_active?(channel) do
    case game_id(channel) do
      {:ok, _id} -> true
      {:error, :no_game} -> false
    end
  end

  def child_spec(wordbot_db) do
    %{
      id: Sqlitex.Server,
      start: {Sqlitex.Server, :start_link, [wordbot_db, [name: __MODULE__]]}
    }
  end

  @doc """
  Gets the ID of the currently running game.

  ## Returns

  * {:ok, id} on success
  * {:error, :no_game} when no game is running for this channel
  """
  def game_id(channel) do
    now = Util.now_unix()

    id =
      with {:ok, rows} <-
             Sqlitex.Server.query(
               __MODULE__,
               "SELECT id FROM game WHERE channel = ?1 AND end > ?2 ORDER BY id DESC",
               bind: [channel, now]
             ),
           [id | _] <- Enum.map(rows, & &1[:id]),
           do: id

    case id do
      [] -> {:error, :no_game}
      id -> {:ok, id}
    end
  end

  def game_id!(channel) do
    {:ok, id} = game_id(channel)
    id
  end

  def last_game_id(channel) do
    id =
      with {:ok, rows} <-
             Sqlitex.Server.query(
               __MODULE__,
               "SELECT id FROM game WHERE channel = ?1 ORDER BY id DESC",
               bind: [channel]
             ),
           [id | _] <- for(row <- rows, do: row[:id]),
           do: id

    case id do
      [] -> {:error, :no_game}
      id -> {:ok, id}
    end
  end

  def add_score(channel, user, word, line) do
    id = game_id!(channel)
    {:ok, _} = Sqlitex.Server.query(
      __MODULE__,
      """
      INSERT INTO score (game, word, user, line)
      VALUES (?1, (SELECT word.id FROM word WHERE game = ?1 AND word = ?2), ?3, ?4)
      """, bind: [id, word, user, line])
  end

  def scores(channel) do
    {:ok, id} = last_game_id(channel)
    {:ok, rows} = Sqlitex.Server.query(
      __MODULE__,
      """
      SELECT user, COUNT(score.id) AS score FROM score
      JOIN game ON score.game = game.id
      WHERE game.id = ?1
      GROUP BY user
      """,
      bind: [id]
    )
    Enum.map(rows, &Map.new/1)
  end

  def leaderboard(channel) do
    {:ok, rows} = Sqlitex.Server.query(
      __MODULE__,
      """
      SELECT user, COUNT(score.id) AS score FROM score
      JOIN game ON score.game = game.id
      WHERE game.channel = ?1
      GROUP BY user
      """,
      bind: [channel]
    )
    Enum.map(rows, &Map.new/1)
  end

  @doc "Gets all words that have not been scored on from the given channel."
  def unmatched_words(channel) do
    id = game_id!(channel)
    {:ok, rows} = Sqlitex.Server.query(
      __MODULE__,
      """
      SELECT word FROM word
      WHERE word.game = ?1
        AND id NOT IN (SELECT score.word FROM score WHERE game = ?1)
      """,
      bind: [id]
    )
    Enum.map(rows, &(&1[:word]))
  end
end
