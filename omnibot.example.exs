alias Omnibot.Config

config = %Config {
  nick: "omnibot_testing",
  server: "irc.bonerjamz.us",
  port: 6667,
  ssl: false,

  plugins: [
    Omnibot.Core,
    {Omnibot.Contrib.OnConnect, commands: [
      ["privmsg", "nickserv", "register", "password123", "omnibot@omni.bot"],
      ["privmsg", "nickserv", "identify", "password123"]
    ]},
    {Omnibot.Contrib.Linkbot, channels: :all},
    {Omnibot.Contrib.Fortune, channels: :all},
    {Omnibot.Contrib.Wordbot, channels: ["#idleville"], ignore: ["username"]},
  ],

  #plugin_paths: [{"plugins", recurse: true}]
}
