defmodule Elementary.AppcenterDashboardWeb.RecentProjectLive do
  @moduledoc """
  Live component that lists information about recently submitted applications.
  """

  use Elementary.AppcenterDashboardWeb, :live_view

  alias Elementary.AppcenterDashboard.{Projects, Service}

  def mount(_params, %{"current_user" => current_user, "url" => url}, socket) do
    if pid = Projects.ensure_created(url) do
      {:ok,
       assign(socket,
         pid: pid,
         info: Projects.info(pid)
       )}
    else
      {:error, "Unable to create project process"}
    end
  end

  def handle_event("refresh", _, socket) do
    {:noreply, socket}
  end

  def render(assigns) do
    Elementary.AppcenterDashboardWeb.LiveView.render("recent_project.html", assigns)
  end
end
