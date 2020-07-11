defmodule Omnibot.PluginSupervisor do
  @moduledoc false

  use Supervisor
  require Logger
  alias Omnibot.State

  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, opts[:cfg], opts)
  end

  @impl true
  def init(cfg) do
    compile_files(cfg.plugin_paths || [])

    # These are plugins that need to be loaded for core functionality of the bot
    core = [
      Omnibot.Core,
    ]

    # Map the plugins in the configuration to the children
    children =
      for plug <- (core ++ cfg.plugins) do
        case plug do
          {name, cfg} -> {name, cfg: cfg ++ name.default_config(), name: name}
          name -> {name, cfg: name.default_config(), name: name}
        end
      end

    # Add each child to the "loaded plugins" list in the State
    Enum.each(children, fn {plugin, opts} -> State.add_loaded_plugin({plugin, opts[:cfg]}) end)

    Supervisor.init(children, strategy: :one_for_one)
  end

  defp compile_files([]), do: nil

  defp compile_files([{path, opts} | plugin_paths]) do
    case {File.exists?(path), File.dir?(path)} do
      {_, true} -> compile_dir(path, opts[:recurse] || false)
      {true, false} -> Code.require_file(path)
      {_, _} -> Logger.error("plugin path '#{path}' does not exist, it will not be loaded")
    end

    compile_files(plugin_paths)
  end

  defp compile_files([path | plugin_paths]) do
    compile_files([{path, []} | plugin_paths])
  end

  defp compile_dir(path, recurse) do
    files =
      File.ls!(path)
      |> Enum.map(fn file -> {Path.join(path, file), [recurse: recurse]} end)
      |> Enum.filter(fn {file, [recurse: recurse]} ->
        (!File.dir?(file) || recurse) && File.exists?(file)
      end)
    compile_files(files)
  end
end
