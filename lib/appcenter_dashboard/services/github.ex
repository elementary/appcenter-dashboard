defmodule Elementary.AppcenterDashboard.GitHubService do
  @moduledoc """
  A wrapper for GitHub API calls.
  """

  @doc """
  Grabs all of the open PR titles in the review repository.

  ## Examples

    iex> open_reviews()
    ["Release com.github.elementary.calculator 3.1.4"]

  """
  def open_reviews() do
  end

  @doc """
  Grabs the latest release version for a GitHub repository.

  ## Examples

    iex> latest_version("elementary/camera")
    {:ok, %Version{}}

    iex> latest_version("ignore/nonexistance")
    {:ok, nil}

  """
  def latest_version(slug) do
    request = Finch.build(:get, "https://api.github.com/repos/#{slug}/releases/latest")

    with {:ok, response} <- Finch.request(request, FinchPool),
         version_tag <- Map.get(response, "tag_name", ""),
         {:ok, version} <- Version.parse(version_tag) do
      version
    else
      {:error, 404} -> {:ok, nil}
      :error -> {:ok, nil}
    end
  end
end
