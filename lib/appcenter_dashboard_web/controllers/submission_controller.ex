defmodule Elementary.AppcenterDashboardWeb.SubmissionController do
  use Elementary.AppcenterDashboardWeb, :controller

  plug :ensure_logged_in

  def index(conn, _params) do
    render(conn, "index.html")
  end

  def add(conn, _params) do
    render(conn, "add.html")
  end

  def status(conn, _params) do
    render(conn, "status.html")
  end

  defp ensure_logged_in(conn, _options) do
    case get_session(conn, :current_user) do
      nil ->
        conn
        |> redirect(to: Routes.homepage_path(conn, :index))
        |> halt()

      _ ->
        conn
    end
  end
end
