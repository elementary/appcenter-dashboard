defmodule Elementary.AppcenterDashboard.Repository do
  @moduledoc """
  A GenServer that handles all of the git repository parsing from the deployed
  reviews repository.
  """

  use GenServer

  alias Elementary.AppcenterDashboard.{Projects, Service}

  @type t :: %{
          rdnn: String.t(),
          source: String.t(),
          commit: String.t(),
          released_version: Version.t()
        }

  @repository_directory "appcenter-reviews"
  @repository_url "https://github.com/elementary/appcenter-reviews"
  @repository_branch "main"
  @repository_file_glob "applications/*.json"

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  @impl true
  def init(opts) do
    Process.send_after(self(), :refresh, 0)
    {:ok, %{releases: [], opts: opts}}
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
        |> Enum.group_by(&Map.get(&1, :rdnn))
        |> Enum.map(fn {_rdnn, releases} ->
          releases
          |> Enum.sort_by(&Map.get(&1, :version))
          |> List.last()
        end)

      Enum.each(releases, &update_project/1)
      Process.send_after(self(), :refresh, 5 * 60 * 1000)

      {:noreply, Map.put(state, :releases, releases)}
    end
  end

  defp update_project(release) do
    release.source
    |> Projects.ensure_created()
    |> Projects.update(release)
  end

  defp parse_file!(path) do
    [rdnn] =
      path
      |> Path.rootname()
      |> Path.split()
      |> Enum.reverse()
      |> Enum.take(1)

    binary = File.read!(path)
    file = Jason.decode!(binary)

    {:ok, source} =
      file
      |> Map.get("source")
      |> Service.parse()

    {:ok, source} = Service.normalize_source(source)

    %{
      rdnn: rdnn,
      source: source,
      commit: Map.get(file, "commit"),
      released_version: file |> Map.get("version") |> Version.parse!()
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
