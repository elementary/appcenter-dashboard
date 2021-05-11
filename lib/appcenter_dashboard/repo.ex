defmodule Elementary.AppcenterDashboard.Repo do
  use Ecto.Repo,
    otp_app: :appcenter_dashboard,
    adapter: Ecto.Adapters.Postgres
end
