alias Omnibot.Config

config = %Config {
  nick: "omnibot",
  server: "chat.freenode.net",
  port: 6667,
  ssl: false,
  channels: ["#idleville"],

  plugins: [
    # Required for operation of Omnibot.
    # Core can be replaced with another implementation, but generally this should be in every config.
    Omnibot.Core,
    # Use OnConnect module to register commands
    {Omnibot.Contrib.OnConnect, commands: [
      ["privmsg", "nickserv", "register", "password123", "omnibot@omni.bot"],
      ["privmsg", "nickserv", "identify", "password123"]
    ]},
    # Use Linkbot to get titles of URLs posted in the chat
    {Omnibot.Contrib.Linkbot, channels: :all},
    # Fortune will spit out fun messages with the !fortune command - try it out!
    {Omnibot.Contrib.Fortune, channels: :all},
    {Omnibot.Contrib.Wordbot, channels: :all, ignore: ["username"]},
  ],

  #plugin_paths: [{"plugins", recurse: true}]
}
