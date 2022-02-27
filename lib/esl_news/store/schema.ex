defmodule EslNews.Store.Schema do
  use GenServer

  @spec start_link(GenServer.options()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, %{}, opts)
  end

  @spec init(any) :: {:ok, any}
  def init(state) do
    setup_store()

    {:ok, state}
  end

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
    :ok = ensure_table_exists()

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

  defp ensure_table_exists() do
    :mnesia.create_table(
      EslNews.Store.Story,
      ram_copies: [node()],
      attributes: EslNews.Store.Story.schema_attrs(),
      index: EslNews.Store.Story.schema_indices([:type])
    )
    |> case do
      {:atomic, :ok} ->
        :ok

      {:aborted, {:already_exists, EslNews.Store.Story}} ->
        :ok
    end
  end
end
