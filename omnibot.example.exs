alias Omnibot.Config

config = %Config {
  nick: "omnibot_testing",
  server: "irc.bonerjamz.us",
  port: 6667,
  ssl: false,

  modules: [
    {Omnibot.Contrib.Linkbot, channels: :all},
    {Omnibot.Contrib.Fortune, channels: ["#idleville"]},
    {Omnibot.Contrib.Wordbot, channels: ["#idleville"]},
  ],

  #module_paths: [{"modules", recurse: true}]
}
