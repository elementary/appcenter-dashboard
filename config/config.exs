# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :appcenter_dashboard,
  ecto_repos: [Elementary.AppcenterDashboard.Repo]

# Configures the endpoint
config :appcenter_dashboard, Elementary.AppcenterDashboardWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "cGznSYCYMRT1JF6D2q1ZDYkYKTo5ZtzjOGi84irFZK8XWSJo44i8yCw8xshuSdYe",
  render_errors: [
    view: Elementary.AppcenterDashboardWeb.ErrorView,
    accepts: ~w(html json),
    layout: false
  ],
  pubsub_server: Elementary.AppcenterDashboard.PubSub,
  live_view: [signing_salt: "g4CBNAea"],
  gzip: false

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"

# Finally import the secret environment specific config. This can be used if a
# developer has special keys they want to set without worry of being included in
# git.
try do
  import_config "#{Mix.env()}.secret.exs"
rescue
  Code.LoadError -> :no_op
  File.Error -> :no_op
end
