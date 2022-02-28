defmodule EslNews.Store.List do
  @moduledoc """
  `EslNews.Store.List` provides a mnesia schema and struct to store List objects,
  as well as helper methods to interact with the storage table.
  """
  require Record

  @required_keys [:id]
  @optional_keys [:items, :time]
  @struct_keys @required_keys ++ @optional_keys
  @record_tuple_size Enum.count(@struct_keys) + 1

  @type r ::
          {__MODULE__, atom, [non_neg_integer, ...], non_neg_integer | nil}
  @type t :: %__MODULE__{
          id: atom,
          items: [non_neg_integer, ...],
          time: non_neg_integer | nil
        }

  @enforce_keys @required_keys
  @derive {Jason.Encoder, only: @struct_keys}
  defstruct @struct_keys

  @doc """
  List all existing EslNews.Store.List records
  """
  @spec all :: list
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
  Persist an EslNews.Store.List in :mnesia
  """
  @spec create(EslNews.Store.List.t()) :: :ok | :record_exists | atom
  def create(%__MODULE__{id: id} = state) when is_atom(id) do
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
  Decode a :mnesia record tuple into an EslNews.Store.List struct

  ## Examples
      iex> EslNews.Store.List.decode({EslNews.Store.List, :topstories, [4,2,3,1], 54321})
      %EslNews.Store.List{id: :topstories, items: [4,2,3,1], time: 54321}
  """
  @spec decode(EslNews.Store.List.r()) :: EslNews.Store.List.t()
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
  Delete an EslNews.Store.List stored in :mnesia
  """
  @spec delete(EslNews.Store.List.t()) :: :ok
  def delete(%__MODULE__{id: id}) do
    {:atomic, result} =
      :mnesia.transaction(fn ->
        :mnesia.delete({__MODULE__, id})
      end)

    result
  end

  @doc """
  Encode an EslNews.Store.List struct into a :mnesia record tuple

  ## Examples
      iex> EslNews.Store.List.encode(%EslNews.Store.List{id: :topstories, items: [4,2,3,1], time: 54321})
      {EslNews.Store.List, :topstories, [4,2,3,1], 54321}
  """
  @spec encode(EslNews.Store.List.t()) :: EslNews.Store.List.r()
  def encode(%__MODULE__{} = list) when is_struct(list) do
    schema_attrs()
    |> Enum.reduce({__MODULE__}, fn key, acc ->
      acc
      |> Tuple.append(Map.get(list, key))
    end)
  end

  @doc """
  Load an EslNews.Store.List stored in :mnesia or return :not_found
  """
  @spec find(atom) :: {:ok, EslNews.Store.List.t()} | {:not_found, nil}
  def find(id) when is_atom(id) do
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
  Available story list names
  """
  @spec lists() :: [atom, ...]
  def lists() do
    [
      :askstories,
      :beststories,
      :jobstories,
      :newstories,
      :showstories,
      :topstories
    ]
  end

  @doc """
  Attributes list for :mnesia table schema definition.
  :id must always be the first attribute
  """
  @spec schema_attrs :: [atom, ...]
  def schema_attrs() do
    @struct_keys
  end

  @doc """
  Zero-based list of attribute positions to be indexed for :mnesia table schema definition.
  :id is indexed by default, will not be included
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
