defmodule Elementary.AppcenterDashboard.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    appstream_config = Application.get_env(:appcenter_dashboard, :appstream)

    children = [
      # Start the HTTP client pools
      {Finch, name: FinchPool},
      # Start the Ecto repository
      Elementary.AppcenterDashboard.Repo,
      # Start the Appstream parsing process
      {Elementary.AppcenterDashboard.Appstream, appstream_config},
      # Start the Telemetry supervisor
      Elementary.AppcenterDashboardWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Elementary.AppcenterDashboard.PubSub},
      # Start the Endpoint (http/https)
      Elementary.AppcenterDashboardWeb.Endpoint
      # Start a worker by calling: Elementary.AppcenterDashboard.Worker.start_link(arg)
      # {Elementary.AppcenterDashboard.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Elementary.AppcenterDashboard.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    Elementary.AppcenterDashboardWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
