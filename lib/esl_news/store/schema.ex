defmodule EslNews.Store.Schema do
  @moduledoc """
  `EslNews.Store.Schema` sets up the `:mnesia` application and creates tables
  for `EslNews.Store.List` and `EslNews.Store.Story`.
  """
  use GenServer

  @spec start_link(GenServer.options()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, %{}, opts)
  end

  @doc """
  Initialize `:mnesia`.
  - Create schema on the current node.
  - Start `:mnesia`
  - Create tables for `EslNews.Store.List` and `EslNews.Store.Story`
  - Wait for table setup to complete before continuing
  """
  @spec init(any) :: {:ok, any}
  def init(state) do
    setup_store()

    {:ok, state}
  end

  @doc """
  Force execution to pause while table setup completes.
  """
  @spec wait_for_tables :: :ok
  def wait_for_tables() do
    :mnesia.wait_for_tables([EslNews.Store.Story], 2000)
    |> case do
      {:timeout, tables_missing} ->
        raise("#{tables_missing}")

      :ok ->
        :ok
    end
  end

  defp setup_store() do
    :ok = ensure_schema_exists()
    :ok = :mnesia.start()
    :ok = ensure_table_exists(EslNews.Store.List, [])
    :ok = ensure_table_exists(EslNews.Store.Story, [:type])

    wait_for_tables()
  end

  defp ensure_schema_exists() do
    :mnesia.create_schema([node()])
    |> case do
      {:error, {_node, {:already_exists, __node}}} ->
        :ok

      :ok ->
        :ok
    end
  end

  defp ensure_table_exists(module, indices) do
    :mnesia.create_table(
      module,
      type: :ordered_set,
      ram_copies: [node()],
      attributes: module.schema_attrs(),
      index: module.schema_indices(indices)
    )
    |> case do
      {:atomic, :ok} ->
        :ok

      {:aborted, {:already_exists, ^module}} ->
        :ok
    end
  end
end
