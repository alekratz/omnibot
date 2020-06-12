alias Omnibot.Irc
alias Omnibot.Msg

defmodule Omnibot.Irc.MsgTest do
  use ExUnit.Case

  # doctest Irc

  test "irc message parsing" do
    assert %Irc.Msg{
      prefix: %Irc.Msg.Prefix{nick: "example.com"},
      command: "PRIVMSG",
      params: [],
    } == Irc.Msg.parse(":example.com PRIVMSG")

    assert %Irc.Msg{
      prefix: %Irc.Msg.Prefix{nick: "example.com"},
      command: "PRIVMSG",
      params: ["#channel", "message text"],
    } == Irc.Msg.parse(":example.com PRIVMSG #channel :message text")

    assert %Irc.Msg{
      prefix: %Irc.Msg.Prefix{nick: "example.com"},
      command: "PRIVMSG",
      params: ["#channel", "message", "text"],
    } == Irc.Msg.parse(":example.com PRIVMSG #channel message text")
  end

  test "irc message prefix parsing" do
    alias Irc.Msg.Prefix
    assert Prefix.parse(":example.com") != %Prefix{}

    %Prefix{
      nick: "example.com"
    } = Prefix.parse("example.com")

    %Prefix{
      nick: "nick"
    } = Prefix.parse("nick")

    %Prefix{
      nick: "nick",
      user: "username"
    } = Prefix.parse("nick!username")

    %Prefix{
      nick: "nick",
      user: "username",
      host: "example.com"
    } = Prefix.parse("nick!username@example.com")
  end

  test "irc message prefix to_string" do
    alias Irc.Msg.Prefix

    prefixes = [
      "example.com",
      "nick!username",
      "nick!username@example.com"
    ]

    for prefix <- prefixes,
        do: assert(Prefix.parse(prefix) |> to_string() == prefix)
  end

  test "irc message to_string" do
    alias Irc.Msg

    msgs = [
      ":example.com PRIVMSG #command",
      ":example.com PRIVMSG #channel :message text"
    ]

    for msg <- msgs, do: assert(Msg.parse(msg) |> to_string() == msg)
  end
end
