import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :appcenter_dashboard, Elementary.AppcenterDashboardWeb.Endpoint, http: [port: 4002]

# Print only warnings and errors during test
config :logger, level: :warn
