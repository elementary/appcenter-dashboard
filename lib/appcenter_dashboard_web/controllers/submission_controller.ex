defmodule Elementary.AppcenterDashboardWeb.SubmissionController do
  use Elementary.AppcenterDashboardWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end

  def add(conn, _params) do
    render(conn, "add.html")
  end

  def status(conn, _params) do
    render(conn, "status.html")
  end
end
