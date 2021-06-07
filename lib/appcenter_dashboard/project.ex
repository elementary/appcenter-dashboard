defmodule Elementary.AppcenterDashboard.Project do
  @moduledoc """
  Handles grabbing information about projects. This information is persisted and
  aggregated from multiple sources, like GitHub open Pull Requests, published
  Appstream data from the flatpak repository, and user input.
  """

  use GenServer

  alias Elementary.AppcenterDashboard.Appstream

  @registry Elementary.AppcenterDashboard.ProjectRegistry
  @supervisor Elementary.AppcenterDashboard.ProjectSupervisor

  @type rdnn :: String.t()

  @doc """
  Starts a new project process to monitor information about the project.
  """
  @spec start_pid(rdnn) :: {:ok, pid()}
  def start_pid(rdnn) do
    DynamicSupervisor.start_child(
      @supervisor,
      {__MODULE__,
       [
         rdnn: rdnn,
         name: {:via, Registry, {@registry, rdnn}}
       ]}
    )
  end

  @doc """
  Lookups the PID for a project process.
  """
  @spec lookup_pid(rdnn) :: {:ok, pid()} | {:error, :not_found}
  def lookup_pid(rdnn) do
    case Registry.lookup(@registry, rdnn) do
      [{pid, _}] -> {:ok, pid}
      [] -> {:error, :not_found}
    end
  end

  @doc """
  Finds the existing PID, or creates a new process and returns that PID.
  """
  @spec find_or_start_pid(rdnn) :: {:ok, pid()}
  def find_or_start_pid(rdnn) do
    with {:error, :not_found} <- lookup_pid(rdnn) do
      start_pid(rdnn)
    end
  end

  @doc """
  Starts a new GenServer project process.
  """
  @spec start_link(Keyword.t()) :: {:ok, pid()}
  def start_link(opts) do
    {name, opts} = Keyword.pop(opts, :name)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  @doc """
  Runs right after the new process is created. Fetches the initial data for
  the project.
  """
  def init(opts) do
    state = %{
      rdnn: Keyword.fetch!(opts, :rdnn),
      last_change: DateTime.utc_now()
    }

    {:ok, state}
  end
end
