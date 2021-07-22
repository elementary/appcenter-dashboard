defmodule Elementary.AppcenterDashboard.Service do
  @moduledoc """
  A Protocol for third party service interactions.
  """

  alias Elementary.AppcenterDashboard.Project

  @services %{
    github: Elementary.AppcenterDashboard.GitHubService
  }

  @type t :: %{
          service:
            String.t()
            | map()
        }

  @doc """
  Parses a URL to connection information needed for a service.
  """
  @callback parse(URI.t()) :: {:ok, t()} | {:ok, nil} | {:error, any}

  @doc """
  Gives a human readable version of the repository data.
  """
  @callback friendly_name(t()) :: {:ok, Project.rdnn()} | {:error, any}

  @doc """
  Creates a default RDNN string for the service connection.
  """
  @callback default_rdnn(t()) :: {:ok, Project.rdnn()} | {:error, any}

  @doc """
  Fetches the latest version for a connection.
  """
  @callback latest_release(t()) :: {:ok, Version.t()} | {:error, any}

  @doc """
  Parses a URL to a service connection string.
  """
  @spec parse(String.t()) :: {:ok, t()} | {:error, any}
  def parse(url) do
    uri = URI.parse(url)

    parse_results =
      @services
      |> Enum.map(fn {service, module} ->
        case apply(module, :parse, [uri]) do
          {:ok, nil} -> {service, nil}
          {:error, message} -> {service, message}
          {:ok, options} -> {service, options}
        end
      end)
      |> Enum.filter(fn {_service, res} -> not is_nil(res) end)
      |> Enum.sort_by(fn {_service, res} -> is_map(res) end)
      |> Enum.at(0)

    case {uri, parse_results} do
      {%{host: nil}, _} ->
        {:error, "Unsupported service"}

      {_, nil} ->
        {:error, "Unsupported service"}

      {_, {_service, message}} when is_binary(message) ->
        {:error, message}

      {_uri, {service, connection}} ->
        {:ok, Map.put(connection, :service, service)}
    end
  end

  @doc """
  Gives a human readable version of the repository data.
  """
  @spec friendly_name(t()) :: {:ok, String.t()} | {:error, any}
  def friendly_name(%{service: service} = connection) do
    @services
    |> Map.get(service)
    |> apply(:friendly_name, [connection])
  end

  @doc """
  Returns a default RDNN string for a project
  """
  @spec default_rdnn(t()) :: {:ok, String.t()} | {:error, any}
  def default_rdnn(%{service: service} = connection) do
    @services
    |> Map.get(service)
    |> apply(:default_rdnn, [connection])
  end

  @doc """
  Returns a default RDNN string for a project
  """
  @spec normalize_source(t()) :: {:ok, String.t()} | {:error, any}
  def normalize_source(%{service: service} = connection) do
    @services
    |> Map.get(service)
    |> apply(:normalize_source, [connection])
  end

  @doc """
  Returns the latest version of a release for the connection
  """
  @spec latest_release(t()) :: {:ok, Version.t()} | {:error, any}
  def latest_release(%{service: service} = connection) do
    @services
    |> Map.get(service)
    |> apply(:latest_release, [connection])
  end
end
