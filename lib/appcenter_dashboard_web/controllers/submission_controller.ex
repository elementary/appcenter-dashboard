defmodule Elementary.AppcenterDashboardWeb.SubmissionController do
  use Elementary.AppcenterDashboardWeb, :controller

  alias Elementary.AppcenterDashboard.Service

  plug :ensure_logged_in

  def index(conn, _params) do
    render(conn, "index.html")
  end

  def add(conn, %{"url" => url}) do
    with {:ok, connection} <- Service.parse(url),
         {:ok, name} <- Service.friendly_name(connection),
         {:ok, rdnn} <- Service.default_rdnn(connection),
         {:ok, release} <- Service.latest_release(connection) do
      render(conn, "add.html", %{
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

  def status(conn, _params) do
    render(conn, "status.html")
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
