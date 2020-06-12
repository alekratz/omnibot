defmodule Omnibot.ModuleSupervisor do
  @moduledoc false

  use Supervisor
  require Logger

  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, opts[:cfg], opts)
  end

  @impl true
  def init(cfg) do
    compile_files(cfg.module_paths || [])

    # Map the modules in the configuration to the children
    children =
      for mod <- cfg.modules do
        case mod do
          {name, cfg} -> {name, cfg: cfg, name: name}
          name -> {name, cfg: [], name: name}
        end
      end

    Supervisor.init(children, strategy: :one_for_one)
  end

  defp compile_files([]), do: nil

  defp compile_files([{path, opts} | module_paths]) do
    case {File.exists?(path), File.dir?(path)} do
      {_, true} -> compile_dir(path, opts[:recurse] || false)
      {true, false} -> Code.require_file(path)
      {_, _} -> Logger.error("module path '#{path}' does not exist, it will not be loaded")
    end

    compile_files(module_paths)
  end

  defp compile_files([path | module_paths]) do
    compile_files([{path, []} | module_paths])
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
