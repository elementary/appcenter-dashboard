defmodule Elementary.AppcenterDashboardWeb.AuthController do
  @moduledoc """
  An endpoint that handles Uberauth endpoints for oauth services.
  """

  use Elementary.AppcenterDashboardWeb, :controller

  alias Elementary.AppcenterDashboard.Cloudflare
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
    conn =
      case create_auth_data(auth) do
        %{service: :stripe} = data -> put_session(conn, :stripe_account, data)
        data -> put_session(conn, :current_user, data)
      end

    conn
    |> configure_session(renew: true)
    |> redirect(to: Routes.submission_path(conn, :index))
  rescue
    _error ->
      conn
      |> put_flash(:error, "Failed to fetch and parse log in information")
      |> redirect(to: Routes.homepage_path(conn, :index))
  end

  defp create_auth_data(%Ueberauth.Auth{provider: :stripe} = auth) do
    result = %{
      service: :stripe,
      card_payments_capability?:
        auth.extra.raw_info.account["capabilities"]["card_payments"] == "active",
      usd_currency_supported?:
        Enum.member?(auth.extra.raw_info.account["currencies_supported"], "usd"),
      name: auth.info.name,
      image: auth.info.image,
      account_id: auth.extra.raw_info.token.other_params["stripe_user_id"],
      public_key: auth.extra.raw_info.token.other_params["stripe_publishable_key"]
    }

    Cloudflare.put(result.public_key, result.account_id)

    result
  end

  defp create_auth_data(%Ueberauth.Auth{} = auth) do
    %{
      service: auth.provider,
      uid: auth.uid,
      token: auth.credentials.token
    }
  end
end
