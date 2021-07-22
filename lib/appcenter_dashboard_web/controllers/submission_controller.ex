defmodule Elementary.AppcenterDashboardWeb.SubmissionController do
  use Elementary.AppcenterDashboardWeb, :controller

  alias Elementary.AppcenterDashboard.Service
  alias Elementary.AppcenterDashboardWeb.RecentProjectsHelper

  plug :ensure_logged_in

  def index(conn, _params) do
    recent_projects = RecentProjectsHelper.list_projects(conn)

    render(conn, "index.html", %{
      recent_projects: recent_projects
    })
  end

  def add(conn, %{"url" => url}) do
    with {:ok, connection} <- Service.parse(url),
         {:ok, name} <- Service.friendly_name(connection),
         {:ok, rdnn} <- Service.default_rdnn(connection),
         {:ok, release} <- Service.latest_release(connection) do
      render(conn, "add.html", %{
        url: url,
        friendly_name: name,
        release: release,
        rdnn: rdnn
      })
    else
      {:error, message} when is_binary(message) ->
        conn
        |> put_flash(:error, message)
        |> redirect(to: Routes.submission_path(conn, :index))
    end
  end

  def status(conn, %{"url" => url}) do
    with {:ok, connection} <- Service.parse(url) do
      conn
      |> RecentProjectsHelper.add_project(url)
      |> render("status.html")
    end
  end

  def get(conn, _params) do
    redirect(conn, to: Routes.submission_path(conn, :index))
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
