defmodule Ueberauth.Strategy.Stripe do
  @moduledoc """
  Provides an Ueberauth strategy for authenticating with Stripe as a connect
  account. Shamelessly stollen most of the code from the GitHub Ueberauth
  Strategy.

  ### Setup

  Include the provider in your configuration for Ueberauth;

      config :ueberauth, Ueberauth,
        providers: [
          stripe: { Ueberauth.Strategy.Stripe, [] }
        ]

  Add your Stripe credentials found on your [developer page](https://dashboard.stripe.com/apikeys)
  to your configuration like so:

      config :ueberauth, Ueberauth.Strategy.Stripe.OAuth,
        client_id: System.get_env("STRIPE_OAUTH_CLIENT_ID"),
        client_secret: System.get_Env("STRIPE_SECRET_KEY")

  If you haven't already, create a pipeline and setup routes for your callback handler

      pipeline :auth do
        Ueberauth.plug "/auth"
      end

      scope "/auth" do
        pipe_through [:browser, :auth]

        get "/:provider/callback", AuthController, :callback
      end

  Create an endpoint for the callback where you will handle the
  `Ueberauth.Auth` struct:

      defmodule MyApp.AuthController do
        use MyApp.Web, :controller

        def callback_phase(%{ assigns: %{ ueberauth_failure: fails } } = conn, _params) do
          # do things with the failure
        end

        def callback_phase(%{ assigns: %{ ueberauth_auth: auth } } = conn, params) do
          # do things with the auth
        end
      end

  """

  use Ueberauth.Strategy,
    default_scope: "read_write",
    send_redirect_uri: true,
    oauth2_module: Ueberauth.Strategy.Stripe.OAuth

  alias Ueberauth.Auth.Info
  alias Ueberauth.Auth.Credentials
  alias Ueberauth.Auth.Extra

  @doc """
  Handles the initial redirect to the Stripe authentication page.

  To customize the scope (permissions) that are requested by Stripe include
  them as part of your url:

      "/auth/stripe?scope=user,public_repo,gist"

  """

  def handle_request!(conn) do
    opts =
      []
      |> with_scopes(conn)
      |> with_state_param(conn)
      |> with_redirect_uri(conn)

    module = option(conn, :oauth2_module)
    redirect!(conn, apply(module, :authorize_url!, [opts]))
  end

  @doc """
  Handles the callback from Stripe.

  When there is a failure from Stripe the failure is included in the
  `ueberauth_failure` struct. Otherwise the information returned from Stripe is
  returned in the `Ueberauth.Auth` struct.
  """
  def handle_callback!(%Plug.Conn{params: %{"code" => code}} = conn) do
    module = option(conn, :oauth2_module)
    token = apply(module, :get_token!, [[code: code]])

    if token.access_token == nil do
      set_errors!(conn, [
        error(token.other_params["error"], token.other_params["error_description"])
      ])
    else
      fetch_account(conn, token)
    end
  end

  @doc false
  def handle_callback!(conn) do
    set_errors!(conn, [error("missing_code", "No code received")])
  end

  @doc """
  Cleans up the private area of the connection used for passing the raw Stripe
  response around during the callback.
  """
  def handle_cleanup!(conn) do
    conn
    |> put_private(:stripe_account, nil)
    |> put_private(:stripe_token, nil)
  end

  @doc """
  Includes the credentials from the Stripe response.
  """
  def credentials(conn) do
    token = conn.private.stripe_token
    scope_string = token.other_params["scope"] || ""
    scopes = String.split(scope_string, ",")

    %Credentials{
      token: token.access_token,
      refresh_token: token.refresh_token,
      expires_at: token.expires_at,
      token_type: token.token_type,
      expires: !!token.expires_at,
      scopes: scopes
    }
  end

  @doc """
  Fetches the fields to populate the info section of the `Ueberauth.Auth`
  struct.
  """
  def info(conn) do
    account = conn.private.stripe_account

    %Info{
      name: account["display_name"],
      image: account["business_logo"]
    }
  end

  @doc """
  Stores the raw information (including the token) obtained from the Stripe
  callback.
  """
  def extra(conn) do
    %Extra{
      raw_info: %{
        token: conn.private.stripe_token,
        account: conn.private.stripe_account
      }
    }
  end

  defp fetch_account(conn, token) do
    conn = put_private(conn, :stripe_token, token)

    case Ueberauth.Strategy.Stripe.OAuth.get(
           token,
           "/v1/accounts/" <> token.other_params["stripe_user_id"]
         ) do
      {:ok, %OAuth2.Response{status_code: 401, body: _body}} ->
        set_errors!(conn, [error("token", "unauthorized")])

      {:ok, %OAuth2.Response{status_code: status_code, body: account}}
      when status_code in 200..399 ->
        put_private(conn, :stripe_account, account)

      {:error, %OAuth2.Error{reason: reason}} ->
        set_errors!(conn, [error("OAuth2", reason)])

      {:error, %OAuth2.Response{body: %{"message" => reason}}} ->
        set_errors!(conn, [error("OAuth2", reason)])

      {:error, _} ->
        set_errors!(conn, [error("OAuth2", "uknown error")])
    end
  end

  defp option(conn, key) do
    Keyword.get(options(conn), key, Keyword.get(default_options(), key))
  end

  defp with_scopes(opts, conn) do
    scopes = conn.params["scope"] || option(conn, :default_scope)

    opts |> Keyword.put(:scope, scopes)
  end

  defp with_redirect_uri(opts, conn) do
    if option(conn, :send_redirect_uri) do
      opts |> Keyword.put(:redirect_uri, callback_url(conn))
    else
      opts
    end
  end
end
