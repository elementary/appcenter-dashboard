defmodule Elementary.AppcenterDashboard.ServiceTest do
  use Elementary.AppcenterDashboardWeb.DataCase

  alias Elementary.AppcenterDashboard.Service

  test "create_connection/1 returns error if unknown host" do
    assert {:error, "Unsupported service"} = Service.parse("nope")
  end

  test "create_connection/1 returns error if unknown url host" do
    assert {:error, "Unsupported service"} = Service.parse("https://example.com")
  end

  test "create_connection/1 returns error from service module" do
    assert {:error, "Unable to parse GitHub path"} =
             Service.parse("https://github.com/elementary")
  end

  test "create_connection/1 passes into a service module when parsing" do
    assert {:ok, %{service: :github}} =
             Service.parse("https://github.com/elementary/appcenter-dashboard")
  end
end
