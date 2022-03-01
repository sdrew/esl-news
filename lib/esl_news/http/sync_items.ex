defmodule EslNews.Http.SyncItems do
  @moduledoc """
  `EslNews.Http.SyncItems`
  """
  use GenServer
  require Logger

  alias EslNews.Http.SyncLists
  alias EslNews.Store.Story

  @client Application.compile_env(:esl_news, :http_client, EslNews.Http.MockClient)
  @sync_tick_ms 1 * 1000

  @doc """
  Process a {list, item_id} tuple. Load existing Store.Story struct or create an empty stub.
  Ignore if item has been processed, otherwise fetch from HTTP endpoint and update in :mnesia.
  If the HTTP request fails, re-enqueue the {list, item_id} tuple with SyncLists.push_item() to
  process it again.
  """
  @spec sync_item({atom, non_neg_integer} | nil) :: :ok
  def sync_item(nil) do
    Logger.info("SyncItems: no item")

    Process.send_after(self(), :sync_tick, @sync_tick_ms)
    :ok
  end

  def sync_item({list, item_id}) when is_atom(list) and is_integer(item_id) do
    Logger.info("SyncItems: #{list} #{item_id}")

    story =
      Story.find(item_id)
      |> case do
        {:ok, story} ->
          story

        {:not_found, nil} ->
          story = struct!(Story, %{id: item_id})
          Story.create(story)
          story
      end

    if story.type === nil do
      @client.story(story.id)
      |> case do
        %{"id" => ^item_id} = data ->
          data =
            data
            |> safe_atomize_keys()

          struct!(Story, data)
          |> Story.save()

        _ ->
          # Re-enqueue item if HTTP request failed
          SyncLists.push_item(list, item_id)
      end
    end

    SyncLists.sweep_list(list)

    Process.send_after(self(), :sync_tick, @sync_tick_ms)
    :ok
  end

  # ============
  # GenServer callbacks
  # ============

  @spec start_link(GenServer.options()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    EslNews.Store.Schema.wait_for_tables()

    GenServer.start_link(__MODULE__, %{}, opts)
  end

  @doc """
  Initialize by dispatching the initial call to :sync_tick
  """
  @impl true
  @spec init(any) :: {:ok, any}
  def init(state) do
    Logger.info("SyncItems worker with #{@client} every #{@sync_tick_ms / 1000}s")

    Process.send(self(), :sync_tick, [])
    {:ok, state}
  end

  @doc """
  On every `:sync_tick` timeout, obtain a {list, item_id} tuple to be updated and pass it to sync_item().
  """
  @impl true
  def handle_info(:sync_tick, state) do
    SyncLists.pull_item()
    |> sync_item()

    {:noreply, state}
  end

  defp safe_atomize_keys(map) do
    map
    |> Map.take(Story.schema_attrs() |> Enum.map(&to_string/1))
    |> Map.new(fn {key, value} ->
      {String.to_existing_atom(key), value}
    end)
  end
end
