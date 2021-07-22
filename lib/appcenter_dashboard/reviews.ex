defmodule Elementary.AppcenterDashboard.Reviews do
  @moduledoc """
  A GenServer that handles all of the Appstream parsing from the deployed
  repository.
  """

  use GenServer

  @type t :: %{
          rdnn: String.t(),
          source: String.t(),
          version: Version.t(),
          commit: String.t()
        }

  @repository_directory "appcenter-reviews"
  @repository_url "https://github.com/elementary/appcenter-reviews"
  @repository_branch "main"
  @repository_file_glob "applications/**/*.json"

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  @doc """
  Returns latest release information for an rdnn
  """
  @spec latest(String.t()) :: t() | nil
  def latest(rdnn) do
    GenServer.call(__MODULE__, {:find, rdnn})
  end

  @impl true
  def init(opts) do
    Process.send_after(self(), :refresh, 0)
    {:ok, %{releases: [], opts: opts}}
  end

  @impl true
  def handle_call({:find, rdnn}, _from, state) do
    found_appstream = Enum.find(state.releases, &(&1.rdnn == rdnn))
    {:reply, found_appstream, state}
  end

  @doc """
  Updates the git repository to main branch, and refreshes all cached data.
  """
  @impl true
  def handle_info(:refresh, state) do
    with {:ok, _repository} <- clean_repository() do
      releases =
        repository_directory()
        |> Path.join(@repository_file_glob)
        |> Path.wildcard()
        |> Enum.map(&parse_file!/1)

      Process.send_after(self(), :refresh, 15 * 60 * 1000)

      {:noreply, Map.put(state, :releases, releases)}
    end
  end

  defp parse_file!(path) do
    [version, rdnn] =
      path
      |> Path.rootname()
      |> Path.split()
      |> Enum.reverse()
      |> Enum.take(2)

    binary = File.read!(path)
    file = Jason.decode!(binary)

    %{
      rdnn: rdnn,
      source: Map.get(file, "source"),
      version: Version.parse!(version),
      commit: Map.get(file, "commit")
    }
  end

  defp clean_repository() do
    with {:ok, repository} <- setup_repository(),
         {:ok, _output} <- Git.checkout(repository, [@repository_branch]),
         {:ok, _output} <- Git.reset(repository, ["--hard"]),
         {:ok, _output} <- Git.clean(repository, ["-fdx"]),
         {:ok, _output} <- Git.fetch(repository) do
      {:ok, repository}
    end
  end

  defp setup_repository() do
    case File.stat(repository_directory()) do
      {:ok, _stat} ->
        {:ok, Git.new(repository_directory())}

      {:error, _anything} ->
        :ok = delete_repository()
        Git.clone([@repository_url, repository_directory()])
    end
  end

  defp delete_repository() do
    case File.rm(repository_directory()) do
      {:ok, _} -> :ok
      {:error, :enoent} -> :ok
      res -> res
    end
  end

  defp repository_directory() do
    Path.join(System.tmp_dir!(), @repository_directory)
  end
end
