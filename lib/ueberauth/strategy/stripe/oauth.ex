defmodule Ueberauth.Strategy.Stripe.OAuth do
  @moduledoc """
  An implementation of OAuth2 for Stripe connect accounts.

  To add your `:client_id` and `:client_secret` include these values in your
  configuration:

      config :ueberauth, Ueberauth.Strategy.Stripe.OAuth,
        client_id: System.get_env("STRIPE_OAUTH_CLIENT_ID"),
        client_secret: System.get_env("STRIPE_SECRET_KEY")

  """

  use OAuth2.Strategy

  @defaults [
    strategy: __MODULE__,
    site: "https://api.stripe.com",
    authorize_url: "https://connect.stripe.com/oauth/authorize",
    token_url: "https://connect.stripe.com/oauth/token"
  ]

  @doc """
  Construct a client for requests to Stripe.

  Optionally include any OAuth2 options here to be merged with the defaults:

      Ueberauth.Strategy.Stripe.OAuth.client(
        redirect_uri: "http://localhost:4000/auth/stripe/callback"
      )

  This will be setup automatically for you in `Ueberauth.Strategy.Stripe`.

  These options are only useful for usage outside the normal callback phase of
  Ueberauth.
  """
  def client(opts \\ []) do
    config =
      :ueberauth
      |> Application.fetch_env!(Ueberauth.Strategy.Stripe.OAuth)
      |> check_credential(:client_id)
      |> check_credential(:client_secret)

    client_opts =
      @defaults
      |> Keyword.merge(config)
      |> Keyword.merge(opts)

    json_library = Ueberauth.json_library()

    client_opts
    |> OAuth2.Client.new()
    |> OAuth2.Client.put_serializer("application/json", json_library)
  end

  @doc """
  Provides the authorize url for the request phase of Ueberauth.

  No need to call this usually.
  """
  def authorize_url!(params \\ [], opts \\ []) do
    opts
    |> client
    |> OAuth2.Client.authorize_url!(params)
  end

  def get(token, url, headers \\ [], opts \\ []) do
    [token: token]
    |> client
    |> put_param("client_secret", client().client_secret)
    |> OAuth2.Client.get(url, headers, opts)
  end

  def get_token!(params \\ [], options \\ []) do
    headers = Keyword.get(options, :headers, [])
    options = Keyword.get(options, :options, [])
    client_options = Keyword.get(options, :client_options, [])

    # At this point we override the normal OAuth2.Client.get_token! because it
    # encodes the authorization header with the client id and secret, which
    # Stripe does not expect. Sadly, there is no way to override thie activity.

    client = client(client_options)

    client =
      client
      |> put_param(:code, Keyword.get(params, :code))
      |> put_param(:grant_type, "authorization_code")
      |> put_param(:client_id, client.client_id)
      |> put_param(:redirect_uri, client.redirect_uri)
      |> merge_params(params)
      |> put_header("authorization", "Basic " <> Base.encode64(client.client_secret <> ":"))
      |> put_headers(headers)

    url = client.token_url <> "?" <> URI.encode_query(client.params)

    case OAuth2.Request.request(:post, client, url, [], headers, options) do
      {:ok, response} ->
        OAuth2.AccessToken.new(response.body)

      {:error, %OAuth2.Response{status_code: code, headers: headers, body: body}} ->
        raise %OAuth2.Error{
          reason: """
          Server responded with status: #{code}

          Headers:

          #{Enum.reduce(headers, "", fn {k, v}, acc -> acc <> "#{k}: #{v}\n" end)}
          Body:

          #{inspect(body)}
          """
        }
    end
  end

  # Strategy Callbacks

  def authorize_url(client, params) do
    OAuth2.Strategy.AuthCode.authorize_url(client, params)
  end

  def get_token(client, params, headers) do
    client
    |> put_param("client_secret", client.client_secret)
    |> put_header("Accept", "application/json")
    |> OAuth2.Strategy.AuthCode.get_token(params, headers)
  end

  defp check_credential(config, key) do
    check_config_key_exists(config, key)

    case Keyword.get(config, key) do
      value when is_binary(value) ->
        config

      {:system, env_key} ->
        case System.get_env(env_key) do
          nil ->
            raise "#{inspect(env_key)} missing from environment, expected in config :ueberauth, Ueberauth.Strategy.Stripe"

          value ->
            Keyword.put(config, key, value)
        end
    end
  end

  defp check_config_key_exists(config, key) when is_list(config) do
    unless Keyword.has_key?(config, key) do
      raise "#{inspect(key)} missing from config :ueberauth, Ueberauth.Strategy.Stripe"
    end

    config
  end

  defp check_config_key_exists(_, _) do
    raise "Config :ueberauth, Ueberauth.Strategy.Stripe is not a keyword list, as expected"
  end
end
