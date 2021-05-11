defmodule Elementary.AppcenterDashboardWeb.HealthController do
  @moduledoc """
  A simple health checking endpoint used for load balancers and kube clusters.
  """

  use Elementary.AppcenterDashboardWeb, :controller

  def index(conn, _params) do
    send_resp(conn, 200, "ok")
  end
end
