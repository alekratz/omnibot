defmodule Omnibot.Contrib.Linkbot do
  use Omnibot.Module
  require Logger

  defmodule Client do
    use Tesla

    plug Tesla.Middleware.Headers, [{"user-agent", "Tesla/Omnibot"}]
    plug Tesla.Middleware.FollowRedirects, max_redirects: 10
    plug Tesla.Middleware.Compression, format: "gzip"

    @title_regex ~r"<title>(?<title>.+)</title>"i

    def get_title(url) do
      if should_get?(url) do
        resp = get!(url)
        %{"title" => title} = Regex.named_captures(@title_regex, resp.body)
        title
      end
    end

    defp should_get?(url) do
      resp = head!(url)
      Tesla.get_header(resp, "content-type")
      |> String.downcase()
      |> String.contains?(["html", "text"])
    end
  end

  @url_regex ~r"\bhttps?://[^\s]+"

  @impl true
  def on_channel_msg(irc, channel, _nick, line) do
    Regex.scan(@url_regex, line)
    |> Enum.map(fn url -> Client.get_title(url) end)
    |> Enum.each(fn title -> Irc.send_to(irc, channel, title) end)
  end
end
