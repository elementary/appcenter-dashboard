defmodule Elementary.AppcenterDashboard.Appstream do
  @moduledoc """
  A GenServer that handles all of the Appstream parsing from the deployed
  repository.
  """

  use GenServer

  @type appstream_data :: %{
          name: String.t(),
          rdnn: String.t(),
          icon: String.t()
        }

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
    found_appstream = Enum.find(state.data, &(&1.rdnn == rdnn))
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
      |> Floki.parse_document!()
      |> Floki.find("component")
      |> Enum.map(&parse_appstream_data(&1, state))

    File.rmdir(local_dir)

    Process.send_after(self(), :refresh, 15 * 60 * 1000)

    {:noreply, Map.put(state, :data, appstream_data)}
  end

  defp parse_appstream_data(component, state) do
    name =
      component
      |> Floki.find("name")
      |> Floki.filter_out(%Floki.Selector{
        attributes: [
          %Floki.Selector.AttributeSelector{
            attribute: "xml:lang"
          }
        ]
      })
      |> Floki.text()

    rdnn =
      component
      |> Floki.find("id")
      |> Enum.at(0)
      |> Floki.text()

    icon_filename =
      component
      |> Floki.find("icon[type=\"cached\"][width=\"64\"]")
      |> Floki.text()

    icon_path =
      if icon_filename != "",
        do: Path.join([state.opts[:icons], "64x64", icon_filename]),
        else: nil

    %{
      name: name,
      rdnn: rdnn,
      icon: icon_path
    }
  end
end
