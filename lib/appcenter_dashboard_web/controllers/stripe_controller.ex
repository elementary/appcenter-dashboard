defmodule Elementary.AppcenterDashboardWeb.StripeController do
  use Elementary.AppcenterDashboardWeb, :controller

  plug :ensure_logged_in

  def index(conn, _params) do
    stripe = get_session(conn, :stripe_account)
    render(conn, "index.html", stripe: stripe)
  end

  defp ensure_logged_in(conn, _options) do
    case get_session(conn, :stripe_account) do
      nil ->
        conn
        |> redirect(to: Routes.auth_path(conn, :index, :stripe))
        |> halt()

      _ ->
        conn
    end
  end
end
