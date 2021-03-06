defmodule EslNews.Store.Story do
  @moduledoc """
  `EslNews.Store.Story` provides a `mnesia` schema and struct to store `EslNews.Store.Story` objects,
  as well as helper methods to interact with the storage table.
  """
  require Record

  @required_keys [:id]
  @optional_keys [:by, :descendants, :score, :time, :title, :type, :url]
  @struct_keys @required_keys ++ @optional_keys
  @record_tuple_size Enum.count(@struct_keys) + 1

  @typedoc """
  `EslNews.Store.Story` record tuple type
  """
  @type r ::
          {__MODULE__, non_neg_integer, String.t() | nil, non_neg_integer, integer,
           non_neg_integer | nil, String.t() | nil, String.t() | nil, String.t() | nil}
  @typedoc """
  `EslNews.Store.Story` struct type
  """
  @type t :: %__MODULE__{
          id: non_neg_integer,
          by: String.t(),
          descendants: non_neg_integer,
          score: integer,
          time: non_neg_integer,
          title: String.t(),
          type: String.t(),
          url: String.t() | nil
        }

  @enforce_keys @required_keys
  @derive {Jason.Encoder, only: @struct_keys}
  defstruct @struct_keys

  @doc """
  All existing `EslNews.Store.Story` records
  """
  @spec all() :: list
  def all() do
    {:atomic, list} =
      :mnesia.transaction(fn ->
        __MODULE__
        |> :mnesia.table_info(:wild_pattern)
        |> :mnesia.match_object()
      end)

    list
    |> Enum.map(fn x -> __MODULE__.decode(x) end)
  end

  @doc """
  All existing `EslNews.Store.Story` records for an `EslNews.Store.List` or list of IDs
  """
  @spec all(atom | [non_neg_integer, ...]) :: list
  def all(:all), do: all()

  def all(list_id) when is_atom(list_id) do
    case EslNews.Store.List.find(list_id) do
      {:ok, find} ->
        find.items
        |> __MODULE__.all()

      {:not_found, _} ->
        []
    end
  end

  def all(ids) when is_list(ids) do
    ids
    |> Enum.map(fn item ->
      __MODULE__.find(item)
      |> case do
        {:ok, story} ->
          story

        {:not_found, _} ->
          nil
      end
    end)
    |> Enum.reject(fn x -> x == nil end)
  end

  @doc """
  Persist an `EslNews.Store.Story` in `:mnesia`
  """
  @spec create(EslNews.Store.Story.t() | non_neg_integer) :: :ok | :record_exists | atom
  def create(id) when is_integer(id) do
    fields = %{id: id}
    create(struct(__MODULE__, fields))
  end

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
  Decode a `:mnesia` record tuple into an `EslNews.Store.Story` struct

  ## Examples
      iex> EslNews.Store.Story.decode({EslNews.Store.Story, 1, "Author", 0, 0, 0, "Title", "story", nil})
      %EslNews.Store.Story{id: 1, by: "Author", descendants: 0, score: 0, time: 0, type: "story", title: "Title", url: nil}
  """
  @spec decode(EslNews.Store.Story.r()) :: EslNews.Store.Story.t()
  def decode(record) when Record.is_record(record) and tuple_size(record) == @record_tuple_size do
    attrs =
      schema_attrs()
      |> Enum.with_index(1)
      |> Enum.map(fn {key, idx} ->
        {key, elem(record, idx)}
      end)

    struct!(__MODULE__, attrs)
  end

  @doc """
  Delete an `EslNews.Store.Story` stored in :mnesia
  """
  @spec delete(EslNews.Store.Story.t()) :: :ok
  def delete(%__MODULE__{id: id}) do
    {:atomic, result} =
      :mnesia.transaction(fn ->
        :mnesia.delete({__MODULE__, id})
      end)

    result
  end

  @doc """
  Encode an `EslNews.Store.Story` struct into a `:mnesia` record tuple

  ## Examples
      iex> EslNews.Store.Story.encode(%EslNews.Store.Story{id: 1, type: "story", title: "Title", by: "Author"})
      {EslNews.Store.Story, 1, "Author", nil, nil, nil, "Title", "story", nil}
  """
  @spec encode(EslNews.Store.Story.t()) :: EslNews.Store.Story.r()
  def encode(%__MODULE__{} = story) when is_struct(story) do
    schema_attrs()
    |> Enum.reduce({__MODULE__}, fn key, acc ->
      acc
      |> Tuple.append(Map.get(story, key))
    end)
  end

  @doc """
  Load an `EslNews.Store.Story` stored in `:mnesia` or return `:not_found`
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
              |> __MODULE__.decode()

            {:ok, record}
        end
      end)

    reason
  end

  @doc """
  Update an existing `EslNews.Store.Story` in `:mnesia`
  """
  @spec save(EslNews.Store.Story.t()) :: :ok | :not_found | atom
  def save(%__MODULE__{id: id} = state) when is_integer(id) do
    {:atomic, reason} =
      :mnesia.transaction(fn ->
        case :mnesia.wread({__MODULE__, id}) do
          [] ->
            :not_found

          _ ->
            __MODULE__.encode(state) |> :mnesia.write()
        end
      end)

    reason
  end

  @doc """
  Attributes list for `:mnesia` table schema definition.
  `:id` must always be the first attribute
  """
  @spec schema_attrs :: [atom, ...]
  def schema_attrs() do
    @struct_keys
  end

  @doc """
  Zero-based list of attribute positions to be indexed for `:mnesia` table schema definition.
  `:id` is indexed by default, will not be included
  """
  @spec schema_indices([atom, ...]) :: [non_neg_integer]
  def schema_indices(keys) do
    keys
    |> Enum.map(fn key ->
      Enum.find_index(@struct_keys, fn s -> s == key end)
    end)
    |> Enum.sort()
    |> List.delete(0)
  end
end
