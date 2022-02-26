defmodule EslNews.Store.Story do
  require Record

  @required_keys [:id, :by, :title, :type]
  @optional_keys []
  @struct_keys @required_keys ++ @optional_keys

  @type t :: %__MODULE__{id: non_neg_integer, by: String.t(), title: String.t(), type: String.t()}

  @enforce_keys @required_keys
  @derive {Jason.Encoder, only: @struct_keys}
  defstruct @struct_keys

  @doc """
  List all existing EslNews.Store.Story records
  """
  @spec all :: list
  def all() do
    {:atomic, list} =
      :mnesia.transaction(fn ->
        EslNews.Store.Story
        |> :mnesia.table_info(:wild_pattern)
        |> :mnesia.match_object()
      end)

    list
    |> Enum.map(fn x -> __MODULE__.decode(x) end)
  end

  @doc """
  Attributes list for :mnesia table schema definition.
  :id must always be the first attribute
  """
  @spec as_schema :: [atom, ...]
  def as_schema() do
    attrs =
      struct(__MODULE__, [])
      |> Map.keys()
      |> Kernel.--([:__struct__, :id])

    [:id] ++ attrs
  end

  @doc """
  Persist an EslNews.Store.Story in :mnesia
  """
  @spec create(EslNews.Store.Story.t()) :: :ok | :record_exists | atom
  def create(%__MODULE__{id: id} = state) when is_integer(id) do
    {:atomic, reason} =
      :mnesia.transaction(fn ->
        case :mnesia.wread({__MODULE__, id}) do
          [] ->
            __MODULE__.encode(state) |> :mnesia.write()

          _ ->
            :record_exists
        end
      end)

    reason
  end

  @doc """
  Decode a :mnesia record tuple into an EslNews.Store.Story struct

  ## Examples
      iex> EslNews.Store.Story.decode({EslNews.Store.Story, 1, "Author", "Title", "story"})
      %EslNews.Store.Story{id: 1, type: "story", title: "Title", by: "Author"}
  """
  @spec decode({EslNews.Store.Story, non_neg_integer, String.t(), String.t(), String.t()}) ::
          EslNews.Store.Story.t()
  def decode(record) when Record.is_record(record) do
    attrs =
      as_schema()
      |> Enum.with_index(1)
      |> Enum.map(fn {key, idx} ->
        {key, elem(record, idx)}
      end)

    struct!(__MODULE__, attrs)
  end

  @spec delete(EslNews.Store.Story.t()) :: :ok
  def delete(%__MODULE__{id: id}) do
    {:atomic, result} =
      :mnesia.transaction(fn ->
        :mnesia.delete({__MODULE__, id})
      end)

    result
  end

  @doc """
  Encode an EslNews.Store.Story struct into a :mnesia record tuple

  ## Examples
      iex> EslNews.Store.Story.encode(%EslNews.Store.Story{id: 1, type: "story", title: "Title", by: "Author"})
      {EslNews.Store.Story, 1, "Author", "Title", "story"}
  """
  @spec encode(EslNews.Store.Story.t()) ::
          {EslNews.Store.Story, non_neg_integer, String.t(), String.t(), String.t()}
  def encode(%__MODULE__{} = story) when is_struct(story) do
    as_schema()
    |> Enum.reduce({__MODULE__}, fn key, acc ->
      acc
      |> Tuple.append(Map.get(story, key))
    end)
  end

  @doc """
  Load an EslNews.Store.Story stored in :mnesia or return :not_found
  """
  @spec find(non_neg_integer) :: {:ok, EslNews.Store.Story.t()} | {:not_found, nil}
  def find(id) when is_integer(id) and id > 0 do
    {:atomic, reason} =
      :mnesia.transaction(fn ->
        case list = :mnesia.read({__MODULE__, id}) do
          [] ->
            {:not_found, nil}

          _ ->
            record =
              list
              |> List.first()
              |> EslNews.Store.Story.decode()

            {:ok, record}
        end
      end)

    reason
  end
end
