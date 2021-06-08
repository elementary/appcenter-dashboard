defmodule Elementary.AppcenterDashboard.Service do
  @moduledoc """
  A Protocol for third party service interactions.
  """

  alias Elementary.AppcenterDashboard.GitHubService
  alias Elementary.AppcenterDashboard.Project

  @type t :: {module(), map()}

  @doc """
  Creates a default RDNN string for the service connection.
  """
  @callback create_connection(URI.t()) :: {:ok, t()} | {:error, any}

  @doc """
  Creates a default RDNN string for the service connection.
  """
  @callback default_rdnn(map()) :: {:ok, Project.rdnn()} | {:error, any}

  @doc """
  Fetches the latest version for a connection.
  """
  @callback latest_release(map()) :: {:ok, Version.t()} | {:error, any}

  @doc """
  Parses a URL to a service connection string.
  """
  @spec create_connection(String.t()) :: {:ok, t()} | {:error, any}
  def create_connection(url) do
    uri = URI.parse(url)

    service_module =
      case uri do
        %{host: "github.com"} -> GitHubService
        _ -> nil
      end

    case {uri, service_module} do
      {%{host: nil}, _} ->
        {:error, "Unable to parse URL"}

      {_, nil} ->
        {:error, "Unsupported service"}

      {uri, service_module} ->
        with {:ok, connection_map} <- apply(service_module, :create_connection, [uri]) do
          {:ok, {service_module, connection_map}}
        end
    end
  end
end
