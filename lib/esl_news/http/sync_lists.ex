defmodule EslNews.Http.SyncLists do
  @moduledoc """
  `EslNews.Http.SyncLists`
  """
  use GenServer
  require Logger

  alias EslNews.Store.List, as: StoreList
  alias EslNews.Store.Story

  @client Application.compile_env(:esl_news, :http_client, EslNews.Http.MockClient)
  @sync_items_count Application.compile_env(:esl_news, :sync_items_count, 10)
  @sync_tick_ms 5 * 60 * 1000

  @doc """
  Dequeue an `{list, item_id}` tuple for processing. `nil` if no tuples remain.
  """
  @spec pull_item() :: {atom, non_neg_integer} | nil
  def pull_item() do
    GenServer.call(__MODULE__, :pull_item)
  end

  @doc """
  Enqueue a `{list, item_id}` tuple for processing.
  """
  @spec push_item(atom, non_neg_integer | String.t()) :: :ok
  def push_item(list, item) do
    GenServer.cast(__MODULE__, {:push_item, list, item})
  end

  @doc """
  Enqueue a list name to fetch from the API as an upcoming items list.
  """
  @spec sync_list(atom) :: :ok
  def sync_list(list) do
    GenServer.cast(__MODULE__, {:sync_list, list})
  end

  @doc """
  Verify that all items in an upcoming list have been fetched
  and convert it to the current items list.
  """
  @spec sweep_list(atom) :: :ok
  def sweep_list(list) do
    GenServer.cast(__MODULE__, {:sweep_list, list})
  end

  # ============
  # GenServer callbacks
  # ============

  @spec start_link(GenServer.options()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    EslNews.Store.Schema.wait_for_tables()

    GenServer.start_link(__MODULE__, MapSet.new(), opts)
  end

  @doc """
  Initialize by dispatching the initial call to `:sync_tick`
  """
  @impl true
  @spec init(any) :: {:ok, any}
  def init(state) do
    Logger.info("SyncLists with #{@client} every #{@sync_tick_ms / 1000}s")

    Process.send(self(), :sync_tick, [])
    {:ok, state}
  end

  @doc """
  `GenServer.call/2` callback.
  - `:pull_item` Obtain next `{list, item_id}` tuple and remove it from state
  """
  @impl true
  def handle_call(:pull_item, _from, state) do
    item =
      state
      |> Enum.at(0)

    state =
      state
      |> MapSet.delete(item)

    {:reply, item, state}
  end

  @doc """
  `GenServer.cast/2` callback.
  - `:push_item` Insert a `{list, item_id}` tuple into state.
  - `:sync_list` Fetch list item IDs from HTTP endpoint and keep only the first `@sync_items_count` entries.
      Save the entries to a temporary upcoming `EslNews.Store.List`, and then create empty stub
      `EslNews.Store.Story` for each ID before pushing the ID into the processing queue.
  - `:sweep_list` Fetch list item IDs from an upcoming list and hydrate them into `EslNews.Store.Story` structs.
      Ensure no stub structs remain by checking their `type` attribute and once all are set, save the upcoming
      list as the current list. Finally, delete the upcoming list to prepare for the next sync cycle.
  """
  @impl true
  def handle_cast({:push_item, list, id}, state) do
    state =
      state
      |> MapSet.put({list, id})

    {:noreply, state}
  end

  @impl true
  def handle_cast({:sync_list, list}, state) do
    Logger.info("Updating #{list} list")

    items =
      @client.list(list)
      |> Enum.slice(0, @sync_items_count)

    list_id = String.to_atom("#{list}_u")
    StoreList.create({list_id, items})

    items
    |> Enum.each(fn id ->
      # Create story stub if not available
      Story.create(id)
      EslNews.Http.SyncLists.push_item(list, id)
    end)

    {:noreply, state}
  end

  @impl true
  def handle_cast({:sweep_list, list}, state) do
    list_id = String.to_atom("#{list}_u")

    with {:ok, upcoming} <- StoreList.find(list_id) do
      Story.all(upcoming.items)
      |> Enum.all?(fn %{type: type} -> type end)
      |> if do
        Logger.info("Set upcoming list to current: #{list}")

        StoreList.create({list, upcoming.items})
        StoreList.delete(upcoming)
      end
    end

    {:noreply, state}
  end

  @doc """
  On every `:sync_tick` timeout, enqueue all lists to be updated and set a new timer.
  """
  @impl true
  def handle_info(:sync_tick, state) do
    @client.lists()
    |> Enum.each(fn list ->
      EslNews.Http.SyncLists.sync_list(list)
    end)

    Process.send_after(self(), :sync_tick, @sync_tick_ms)
    {:noreply, state}
  end
end
