defmodule Elementary.AppcenterDashboard.GitHubServiceTest do
  use Elementary.AppcenterDashboardWeb.DataCase

  alias Elementary.AppcenterDashboard.GitHubService

  test "create_connection/1 allows normal repo URL" do
    uri = URI.parse("https://github.com/elementary/appcenter-dashboard")

    assert {:ok, %{owner: "elementary", repository: "appcenter-dashboard"}} =
             GitHubService.parse(uri)
  end

  test "create_connection/1 allows other repository urls" do
    uri = URI.parse("https://github.com/elementary/appcenter-dashboard/issues")

    assert {:ok, %{owner: "elementary", repository: "appcenter-dashboard"}} =
             GitHubService.parse(uri)
  end

  test "create_connection/1 errors out GitHub url without owner and repository in first segments" do
    uri = URI.parse("https://github.com/elementary/")
    assert {:error, "Unable to parse GitHub path"} = GitHubService.parse(uri)
  end

  test "create_connection/1 errors out GitHub url without a path" do
    uri = URI.parse("https://github.com")
    assert {:error, "Unable to parse GitHub path"} = GitHubService.parse(uri)
  end
end
