defmodule Elementary.AppcenterDashboardWeb.LayoutView do
  use Elementary.AppcenterDashboardWeb, :view

  alias Elementary.AppcenterDashboardWeb.Endpoint

  defp year() do
    Map.get(DateTime.utc_now(), :year)
  end
end
