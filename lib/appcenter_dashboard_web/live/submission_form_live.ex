defmodule Elementary.AppcenterDashboardWeb.SubmissionFormLive do
  @moduledoc """
  Live component that validates a given URL is able to be imported.
  """

  use Elementary.AppcenterDashboardWeb, :live_view

  alias Elementary.AppcenterDashboard.Service

  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       url: "",
       error: nil
     )}
  end

  def handle_event("validate", %{"url" => ""}, socket) do
    {:noreply, assign(socket, error: "Please enter a valid URL")}
  end

  def handle_event("validate", %{"url" => url}, socket) do
    case Service.parse(url) do
      {:error, message} ->
        {:noreply, assign(socket, url: url, error: message)}

      {:ok, connection} ->
        {:noreply, assign(socket, url: url, error: nil)}
    end
  end

  def render(assigns) do
    Elementary.AppcenterDashboardWeb.LiveView.render("submission_form.html", assigns)
  end
end
