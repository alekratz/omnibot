alias Omnibot.Irc
alias Omnibot.Util

defmodule Omnibot.Irc.Msg do
  defmodule Prefix do
    defstruct [:nick, :user, :host]

    @prefix_regex ~r/(?<nick>[^!]+)(!(?<user>[^@]+)(@(?<host>.+))?)?/
    def parse(prefix) do
      cap = Regex.named_captures(@prefix_regex, prefix)

      if cap do
        %{
          "nick" => nick,
          "user" => user,
          "host" => host
        } = cap

        %Irc.Msg.Prefix{
          nick: nick,
          user: if(user == "", do: nil, else: user),
          host: if(host == "", do: nil, else: host)
        }
      else
        nil
      end
    end
  end

  @enforce_keys [:command]
  defstruct prefix: nil, command: nil, params: []

  @msg_regex ~r/
    ^(:(?P<prefix>[^ ]+)\ )?
    (?<command>[a-zA-Z]+|[0-9]{3})
    (?<params>(\ [^: \r\n]+)*)
    (?<trailing>\ :[^\r\n]+)?
  /x

  def parse(msg) do
    %{
      "prefix" => prefix,
      "command" => command,
      "params" => params,
      "trailing" => trailing
    } = Regex.named_captures(@msg_regex, msg)

    prefix = Irc.Msg.Prefix.parse(prefix)

    params =
      String.slice(params, 1..-1)
      |> String.split(" ")
      |> Enum.filter(fn s -> String.length(s) > 0 end)

    trailing =
      trailing
      |> String.slice(2..-1)
      |> Util.string_or_nil()

    params = if trailing, do: params ++ [trailing], else: params

    %Irc.Msg{
      prefix: prefix,
      command: command,
      params: params,
    }
  end
end

defimpl String.Chars, for: Irc.Msg.Prefix do
  def to_string(prefix) do
    nick = prefix.nick || ""
    user = if prefix.user, do: "!#{prefix.user}", else: ""
    host = if prefix.host, do: "@#{prefix.host}", else: ""
    "#{nick}#{user}#{host}"
  end
end

defimpl String.Chars, for: Irc.Msg do
  def to_string(msg) do
    prefix =
      case String.Chars.to_string(msg.prefix) do
        "" -> ""
        p -> ":#{p}"
      end

    # Figure out where "trailing" parameters begin, e.g.
    # ["privmsg", "param", "some message", "with another param"]
    #
    #   becomes
    #
    # {["privmsg", "param"], ["some message", "with another param"]}
    #
    {params, trailing} = Enum.split_while(msg.params, fn param -> !String.contains?(param, " ") end)

    # If trailing parameters exist, then join them with a space character and prefix with a colon,
    # appending it as another list item to the non-trailing parameter list
    #
    # If trailing parameters don't exist, don't append anything
    params = params ++
      if length(trailing) > 0,
        do: [":" <> Enum.join(trailing, " ")],
        else: []

    ([prefix, msg.command] ++ params)
    |> Enum.filter(fn n -> String.length(n) > 0 end)
    |> Enum.join(" ")
  end
end
