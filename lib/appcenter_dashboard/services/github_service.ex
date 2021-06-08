defmodule Elementary.AppcenterDashboard.GitHubService do
  @moduledoc """
  A wrapper for GitHub API calls.
  """

  alias Elementary.AppcenterDashboard.Project

  @behavior Elementary.AppcenterDashboard.Service

  @type t :: %{
          owner: String.t(),
          repository: String.t()
        }

  @doc """
  Creates a default RDNN string for the service connection.
  """
  @impl true
  @spec create_connection(URI.t()) :: {:ok, t()} | {:error, any}
  def create_connection(%{path: path}) do
    case String.split(path, "/", parts: 3, trim: true) do
      [owner, repository, _others] -> {:ok, %{owner: owner, repository: repository}}
      [owner, repository] -> {:ok, %{owner: owner, repository: repository}}
      _ -> {:error, "Unable to parse GitHub path"}
    end
  end

  @doc """
  Creates a default RDNN string for a GitHub project.
  """
  @impl true
  @spec default_rdnn(t()) :: {:ok, Project.rdnn()} | {:error, any}
  def default_rdnn(%{owner: owner, repository: repository}) do
    {:ok, "com.github.#{owner}.#{repository}"}
  end

  @doc """
  Grabs the latest release version for a GitHub repository.
  """
  @impl true
  @spec latest_version(t()) :: {:ok, t()} | {:error, any}
  def latest_version(%{owner: owner, repository: repository}) do
    request =
      Finch.build(:get, "https://api.github.com/repos/#{owner}/#{repository}/releases/latest")

    with {:ok, response} <- Finch.request(request, FinchPool),
         version_tag <- Map.get(response, "tag_name", ""),
         {:ok, version} <- Version.parse(version_tag) do
      version
    else
      {:error, 404} -> {:error, "Project does not have a stable release"}
      :error -> {:error, "Latest release is not SemVer"}
    end
  end

  @doc """
  Grabs all of the open PR titles in the review repository.

  ## Examples

    iex> open_reviews()
    ["Release com.github.elementary.calculator 3.1.4"]

  """
  def open_reviews() do
  end
end
