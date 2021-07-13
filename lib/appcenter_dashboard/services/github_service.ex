defmodule Elementary.AppcenterDashboard.GitHubService do
  @moduledoc """
  A wrapper for GitHub API calls.
  """

  @behaviour Elementary.AppcenterDashboard.Service

  @parse_regex ~r/^\/([A-Za-z0-9_.-]+)\/([A-Za-z0-9_.-]+)/

  @impl true
  def parse(%{path: path}) when is_binary(path) do
    case Regex.run(@parse_regex, path) do
      [_path, owner, repository | _extra] -> {:ok, %{owner: owner, repository: repository}}
      _ -> {:error, "Unable to parse GitHub path"}
    end
  end

  def parse(%{host: "github.com"}), do: {:error, "Unable to parse GitHub path"}
  def parse(_uri), do: {:ok, nil}

  @impl true
  def friendly_name(%{owner: owner, repository: repository}) do
    {:ok, "#{owner}/#{repository}"}
  end

  @impl true
  def default_rdnn(%{owner: owner, repository: repository}) do
    {:ok, "com.github.#{owner}.#{repository}"}
  end

  @impl true
  def latest_release(%{owner: owner, repository: repository}) do
    request =
      Finch.build(:get, "https://api.github.com/repos/#{owner}/#{repository}/releases/latest")

    with {:ok, %{status: status, body: body}} when status in 200..299 <-
           Finch.request(request, FinchPool),
         {:ok, response} <- Jason.decode(body),
         version_tag <- Map.get(response, "tag_name", ""),
         {:ok, version} <- Version.parse(version_tag) do
      {:ok, version}
    else
      {:error, 404} -> {:error, "Project does not have a stable release"}
      :error -> {:error, "Latest release is not SemVer"}
    end
  end
end
