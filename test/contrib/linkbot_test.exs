defmodule LinkbotTest do
  use ExUnit.Case, async: true

  alias Omnibot.Contrib.Linkbot

  test "blacklist blocks local addresses" do
    blocked_hosts = [
      "localhost",
      "remote",
      "remote.local",
      "remote.corp.local",
      "127.0.0.1",
      "192.168.0.1",
      "192.168.1.1",
      "192.168.1.255",
      "10.1.1.24",
      "10.1.1.255",
      "172.1.1.22",
      "172.1.1.255",
    ]
    allowed_hosts = [
      "local.tld",
      "localhost.com",
      "local.remote.com",
      "remote.local.com",
    ]

    Enum.each(blocked_hosts, fn host ->
      assert Linkbot.blacklisted?("http://#{host}")
      assert Linkbot.blacklisted?("http://#{host}/")
      assert Linkbot.blacklisted?("http://foo:bar@#{host}/")

      assert Linkbot.blacklisted?("https://#{host}")
      assert Linkbot.blacklisted?("https://#{host}/")
      assert Linkbot.blacklisted?("https://foo:bar@#{host}/")
    end)

    Enum.each(allowed_hosts, fn host ->
      assert !Linkbot.blacklisted?("http://#{host}")
      assert !Linkbot.blacklisted?("http://#{host}/")
      assert !Linkbot.blacklisted?("http://foo:bar@#{host}/")

      assert !Linkbot.blacklisted?("https://#{host}")
      assert !Linkbot.blacklisted?("https://#{host}/")
      assert !Linkbot.blacklisted?("https://foo:bar@#{host}/")
    end)
  end
end
