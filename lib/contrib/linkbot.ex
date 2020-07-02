defmodule Omnibot.Contrib.Linkbot do
  use Omnibot.Module
  require Logger

  @default_config timeout: 30_000
  @hostname_blacklist ~r/(^localhost$|\.local$|\.localdomain$|\.home$|^[^.]+$|^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$)/i

  def blacklisted?(url) do
    host = URI.parse(url).host
    Regex.match?(@hostname_blacklist, host)
  end

  defmodule Client do
    use Tesla
    alias Omnibot.Contrib.Linkbot

    plug Tesla.Middleware.Headers, [{"user-agent", "Tesla/Omnibot"}]
    plug Tesla.Middleware.FollowRedirects, max_redirects: 10
    plug Tesla.Middleware.Compression, format: "gzip"

    # TODO instead of checking for <title> exclusively, do this:
    # 1. check for "meta" tag (in the header) with a "property" attribute of "og:title", and fetch the "content" attribute of that tag
    # 2. check for meta tag with attribute "name" == "title", and fetch "content" attribute
    # 3. Fall back to the <title>

    @title_regex ~r"<title>(?<title>.+)</title>"i

    def get_title(url) do
      if should_get?(url) do
        Logger.info("Fetching #{url}")
        resp = get!(url)
        %{"title" => title} = Regex.named_captures(@title_regex, resp.body)
        title
      end
    end

    defp should_get?(url) do
      if Linkbot.blacklisted?(url) do
        false
      else
        resp = head!(url)
        Tesla.get_header(resp, "content-type")
        |> String.downcase()
        |> String.contains?(["html", "text"])
      end
    end
  end

  @url_regex ~r"\bhttps?://[^\s]+"

  @impl true
  def on_channel_msg(irc, channel, _nick, line) do
    Regex.scan(@url_regex, line)
    |> Enum.flat_map(& &1)
    |> Enum.map(fn url -> Client.get_title(url) end)
    |> Enum.each(fn title -> Irc.send_to(irc, channel, title) end)
  end

end
