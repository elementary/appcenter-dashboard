defmodule Elementary.AppcenterDashboard.GitHubService do
  @moduledoc """
  A wrapper for GitHub API calls.
  """

  @behaviour Elementary.AppcenterDashboard.Service

  @parse_regex ~r/^\/([A-Za-z0-9_.-]+)\/([A-Za-z0-9_.-]+)/

  @impl true
  def parse(%{path: path}) when is_binary(path) do
    case Regex.run(@parse_regex, path) do
      [_path, owner, repository | _extra] ->
        repository = String.replace_trailing(repository, ".git", "")
        {:ok, %{owner: owner, repository: repository}}

      _ ->
        {:error, "Unable to parse GitHub path"}
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
  def normalize_source(%{owner: owner, repository: repository}) do
    {:ok, "https://github.com/#{owner}/#{repository}"}
  end

  @impl true
  def latest_release(connection) do
    with {:ok, %{status: status, body: body}} when status in 200..299 <-
           get_latest_release(connection),
         version_tag <- Map.get(body, "tag_name", ""),
         {:ok, version} <- Version.parse(version_tag) do
      {:ok, version}
    else
      {:ok, %{status: 404}} -> {:error, "Project does not have a stable release"}
      {:ok, %{body: %{message: message}}} -> {:error, message}
      :error -> {:error, "Latest release is not SemVer"}
      _res -> {:error, "Unable to get the latest release"}
    end
  end

  defp get_latest_release(%{owner: owner, repository: repository}) do
    request =
      Finch.build(:get, "https://api.github.com/repos/#{owner}/#{repository}/releases/latest")

    with {:ok, %{body: body} = res} <- Finch.request(request, FinchPool),
         {:ok, response} <- Jason.decode(body) do
      {:ok, Map.put(res, :body, response)}
    end
  end
end
