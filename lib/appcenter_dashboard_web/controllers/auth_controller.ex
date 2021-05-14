defmodule Elementary.AppcenterDashboardWeb.AuthController do
  @moduledoc """
  An endpoint that handles Uberauth endpoints for oauth services.
  """

  use Elementary.AppcenterDashboardWeb, :controller

  alias Ueberauth.Strategy.Helpers

  plug Ueberauth

  def index(conn, _params) do
    redirect(conn, to: Helpers.callback_url(conn))
  end

  def callback(%{assigns: %{ueberauth_failure: _fails}} = conn, _params) do
    conn
    |> put_flash(:error, "Failed to log in")
    |> redirect(to: Routes.homepage_path(conn, :index))
  end

  def callback(%{assigns: %{ueberauth_auth: auth}} = conn, _params) do
    conn
    |> put_session(:current_user, create_auth_data(auth))
    |> configure_session(renew: true)
    |> redirect(to: Routes.submission_path(conn, :index))
  rescue
    _ ->
      conn
      |> put_flash(:error, "Failed to fetch log in information")
      |> redirect(to: Routes.homepage_path(conn, :index))
  end

  defp create_auth_data(%Ueberauth.Auth{} = auth) do
    %{
      service: auth.provider,
      uid: auth.uid,
      token: auth.credentials.token
    }
  end
end
