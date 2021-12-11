defmodule Elementary.AppcenterDashboard.Cloudflare do
  @moduledoc """
  Handles calling the CloudFlare KV store to save the Stripe account and public
  key.
  """

  @cloudflare "https://api.cloudflare.com/client/v4"
  @namespace_id "18fa723fb2424451ba3b44a509ae7e0b"

  def put(public_key, account_id) do
    headers = [{"Authorization", "Bearer " <> config()[:api_key]}]

    url =
      @cloudflare <>
        "/accounts/#{config()[:account_id]}/storage/kv/namespaces/#{@namespace_id}/values/#{public_key}"

    :put
    |> Finch.build(url, headers, account_id)
    |> Finch.request(FinchPool)
  end

  defp config(), do: Application.get_env(:appcenter_dashboard, __MODULE__)
end
