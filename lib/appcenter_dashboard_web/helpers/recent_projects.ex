defmodule Elementary.AppcenterDashboardWeb.RecentProjectsHelper do
  @moduledoc """
  Helper to work with the recent projects list.
  """

  use Elementary.AppcenterDashboardWeb, :controller

  @doc """
  Lists all of the recent projects for the user.
  """
  def list_projects(conn) do
    case get_session(conn, :projects) do
      nil -> []
      projects -> projects
    end
  end

  @doc """
  Adds a project to the user's recent projects.
  """
  def add_project(conn, url) do
    current = list_projects(conn)
    exists? = Enum.member?(current, url)

    if exists? do
      conn
    else
      new_list =
        current
        |> List.insert_at(0, url)
        |> Enum.take(5)

      put_session(conn, :projects, new_list)
    end
  end
end
