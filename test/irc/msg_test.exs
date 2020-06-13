alias Omnibot.Irc.Msg


defmodule Omnibot.MsgTest do
  use ExUnit.Case

  # doctest Irc

  test "irc message parsing" do
    assert %Msg{
      prefix: %Msg.Prefix{nick: "example.com"},
      command: "PRIVMSG",
      params: [],
    } == Msg.parse(":example.com PRIVMSG")

    assert %Msg{
      prefix: %Msg.Prefix{nick: "example.com"},
      command: "PRIVMSG",
      params: ["#channel", "message text"],
    } == Msg.parse(":example.com PRIVMSG #channel :message text")

    assert %Msg{
      prefix: %Msg.Prefix{nick: "example.com"},
      command: "PRIVMSG",
      params: ["#channel", "message", "text"],
    } == Msg.parse(":example.com PRIVMSG #channel message text")
  end

  test "irc message prefix parsing" do
    alias Msg.Prefix
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
    alias Msg.Prefix

    prefixes = [
      "example.com",
      "nick!username",
      "nick!username@example.com"
    ]

    for prefix <- prefixes,
        do: assert(Prefix.parse(prefix) |> to_string() == prefix)
  end

  test "irc message to_string" do
    msgs = [
      ":example.com PRIVMSG #command",
      ":example.com PRIVMSG #channel :message text"
    ]

    for msg <- msgs, do: assert(Msg.parse(msg) |> to_string() == msg)
  end

  test "irc message extracts channel properly" do
    msg = Msg.parse(":example.com PRIVMSG #channel message text")
    assert Msg.channel(msg) == "#channel"

    msg = Msg.parse(":example.com JOIN #join")
    assert Msg.channel(msg) == "#join"

    msg = Msg.parse(":example.com PART #part")
    assert Msg.channel(msg) == "#part"

    msg = Msg.parse(":example.com KICK #kicked nick")
    assert Msg.channel(msg) == "#kicked"

    msg = Msg.parse(":example.com PING 1234")
    assert Msg.channel(msg) == nil
  end
end
