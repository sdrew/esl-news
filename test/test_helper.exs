defmodule EslNews.Test.TestHelper do
  @doc """
  Convert map keys to atoms. Unsafe if keys are unkown, use only for fixtures.
  """
  @spec atomize_keys(map) :: map
  def atomize_keys(source) do
    source
    |> Map.new(fn {key, value} ->
      {String.to_atom(key), value}
    end)
  end

  @doc """
  Load JSON fixture file
  """
  @spec load_fixture(:items | :lists | :users, String.t() | non_neg_integer) :: list | map
  def load_fixture(:items, key), do: EslNews.Http.MockClient.story(key)
  def load_fixture(:lists, key), do: EslNews.Http.MockClient.list(key)
  def load_fixture(:users, key), do: EslNews.Http.MockClient.user(key)

  @doc """
  Load JSON fixture files into a map indexed by filename
  """
  @spec load_fixtures(:items | :lists | :users, [atom | String.t() | non_neg_integer, ...]) :: map
  def load_fixtures(scope, keys) do
    keys
    |> Enum.map(fn key ->
      fixture =
        load_fixture(scope, key)
        |> case do
          %{} = fxt ->
            fxt |> atomize_keys()

          [_ | _] = fxt ->
            fxt

          [] ->
            []
        end

      {key, fixture}
    end)
    |> Enum.into(%{})
  end
end

ExUnit.start()
