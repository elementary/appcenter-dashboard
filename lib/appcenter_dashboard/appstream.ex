defmodule Elementary.AppcenterDashboard.Appstream do
  @moduledoc """
  A GenServer that handles all of the Appstream parsing from the deployed
  repository.
  """

  use GenServer

  import Meeseeks.CSS

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  @doc """
  Returns Appstream data for a given RDNN
  """
  def find(rdnn) do
    GenServer.call(__MODULE__, {:find, rdnn})
  end

  @impl true
  def init(opts) do
    Process.send_after(self(), :refresh, 0)
    {:ok, %{opts: opts}}
  end

  @impl true
  def handle_call({:find, rdnn}, _from, state) do
    found_appstream = Enum.find(state.appstream, &(&1.rdnn == rdnn))
    {:reply, found_appstream, state}
  end

  @doc """
  Downloads the Appstream information and parses it for use in other functions.

  TODO: Make it uncompress in memory instead of writing to a file
  """
  @impl true
  def handle_info(:refresh, state) do
    remote_url = state.opts[:file]
    local_dir = System.tmp_dir!()
    local_compressed_file = Path.join(local_dir, "appstream.xml.gz")

    {:ok, response} =
      Finch.build(:get, remote_url)
      |> Finch.request(FinchPool)

    File.write!(local_compressed_file, response.body)

    appstream_data =
      local_compressed_file
      |> File.stream!([{:read_ahead, 100_000}, :compressed])
      |> Enum.to_list()
      |> IO.iodata_to_binary()
      |> Meeseeks.all(css("component"))
      |> Enum.map(&parse_appstream_data/1)

    File.rmdir(local_dir)

    Process.send_after(self(), :refresh, 24 * 60 * 60 * 1000)

    {:noreply, Map.put(state, :data, appstream_data)}
  end

  defp parse_appstream_data(appstream) do
    name = Meeseeks.one(appstream, css("name"))
    rdnn = Meeseeks.one(appstream, css("id"))

    %{
      name: Meeseeks.text(name),
      rdnn: Meeseeks.text(rdnn)
    }
  end
end
