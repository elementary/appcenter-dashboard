defmodule Elementary.AppcenterDashboard.Project do
  @moduledoc """
  Handles grabbing information about projects. This information is persisted and
  aggregated from multiple sources, like GitHub open Pull Requests, published
  Appstream data from the flatpak repository, and user input.
  """

  defstruct [
    :name,
    :rdnn,
    :icon,
    :source,
    :commit,
    :released_version,
    :reviewing_version
  ]

  use GenServer

  @type t :: %{
          name: String.t(),
          rdnn: String.t(),
          icon: String.t(),
          source: String.t(),
          released_version: Version.t(),
          released_at: DateTime.t(),
          reviewing_version: Version.t(),
          reviewing_at: DateTime.t()
        }

  def start_link(source) do
    GenServer.start_link(__MODULE__, source)
  end

  @impl true
  def init(source) do
    {:ok, %__MODULE__{source: source}}
  end

  @impl true
  def handle_call(:info, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_cast({:update, values}, state) do
    {:noreply, Map.merge(state, values)}
  end
end
