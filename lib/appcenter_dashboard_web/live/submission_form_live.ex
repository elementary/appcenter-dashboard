defmodule Elementary.AppcenterDashboardWeb.SubmissionFormLive do
  @moduledoc """
  Live component that validates a given URL is able to be imported.
  """

  use Elementary.AppcenterDashboardWeb, :live_view

  alias Elementary.AppcenterDashboard.Service

  def mount(%{"url" => url}, _session, socket) do
    case Service.create_connection(url) do
      {:error, message} ->
        {:ok,
         assign(socket,
           url: url,
           error: message
         )}

      {:ok, connection} ->
        {:ok,
         assign(socket,
           url: url,
           error: nil
         )}
    end
  end

  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       url: "",
       error: nil
     )}
  end

  def handle_event("input", %{"url" => url}, socket) do
    {:noreply,
     assign(socket,
       url: url,
       error: nil
     )}
  end

  def handle_event("submit", %{"url" => ""}, socket) do
    {:noreply, assign(socket, error: "Please enter a valid URL")}
  end

  def handle_event("submit", %{"url" => url}, socket) do
    case Service.create_connection(url) do
      {:error, message} ->
        {:noreply, assign(socket, url: url, error: message)}

      {:ok, connection} ->
        {:noreply, push_redirect(socket, to: Routes.submission_path(socket, :add))}
    end
  end

  def render(assigns) do
    Elementary.AppcenterDashboardWeb.LiveView.render("submission_form.html", assigns)
  end
end
