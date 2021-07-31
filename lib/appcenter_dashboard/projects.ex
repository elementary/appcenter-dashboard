defmodule Elementary.AppcenterDashboard.Projects do
  @moduledoc """
  Handles the higher level supervising and functions for projects.
  """

  alias Elementary.AppcenterDashboard.Project

  @registry Elementary.AppcenterDashboard.ProjectRegistry
  @supervisor Elementary.AppcenterDashboard.ProjectSupervisor

  def ensure_created(source) do
    case Registry.lookup(@registry, source) do
      [{_, pid}] ->
        pid

      [] ->
        {:ok, pid} = DynamicSupervisor.start_child(@supervisor, {Project, source})
        Registry.register(@registry, source, pid)
        pid
    end
  end

  def find(key, value) do
    @supervisor
    |> DynamicSupervisor.which_children()
    |> Enum.map(fn {_, pid, _, _} -> pid end)
    |> Enum.find(fn pid ->
      case info(pid) do
        nil -> false
        info -> Map.get(info, key) == value
      end
    end)
  end

  def info(pid) do
    GenServer.call(pid, :info)
  end

  def update(pid, values) do
    GenServer.cast(pid, {:update, values})
  end
end
