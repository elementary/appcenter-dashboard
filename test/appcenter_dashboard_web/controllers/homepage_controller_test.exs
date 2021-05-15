defmodule Elementary.AppcenterDashboardWeb.HomepageControllerTest do
  use Elementary.AppcenterDashboardWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, "/")
    assert html_response(conn, 200) =~ "Publish on AppCenter"
  end
end
