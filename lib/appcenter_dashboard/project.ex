defmodule Elementary.AppcenterDashboard.Project do
  @moduledoc """
  Handles grabbing information about projects. This information is persisted and
  aggregated from multiple sources, like GitHub open Pull Requests, published
  Appstream data from the flatpak repository, and user input.
  """

  defstruct [
    :name,
    :rdnn,
    :icon,
    :released_version,
    :released_at,
    :reviewing_version,
    :reviewing_at
  ]

  use GenServer

  alias Elementary.AppcenterDashboard.Appstream

  @registry Elementary.AppcenterDashboard.ProjectRegistry
  @supervisor Elementary.AppcenterDashboard.ProjectSupervisor

  @type rdnn :: String.t()
  @type t :: %{
          name: String.t(),
          rdnn: rdnn,
          icon: String.t(),
          released_version: Version.t(),
          released_at: DateTime.t(),
          reviewing_version: Version.t(),
          reviewing_at: DateTime.t()
        }

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
  Grabs information about the project
  """
  @spec info(pid()) :: t()
  def info(pid), do: GenServer.call(pid, :info)

  @doc """
  Updates information about a project
  """
  @spec update(pid(), map) :: :ok
  def update(pid, info), do: GenServer.call(pid, {:update, info})

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
  @impl true
  def init(opts) do
    {:ok,
     %__MODULE__{
       rdnn: Keyword.fetch!(opts, :rdnn)
     }}
  end

  @impl true
  def handle_call(:info, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_call({:update, new_info}, _from, state) do
    updated_state = struct(state, new_info)
    {:reply, updated_state, updated_state}
  end
end
