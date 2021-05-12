defmodule Elementary.AppcenterDashboardWeb.SubmissionController do
  use Elementary.AppcenterDashboardWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
