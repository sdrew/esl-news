defmodule EslNews.Http.MockClient do
  @fixtures_dir Path.join([File.cwd!(), "test", "fixtures"])

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
  List of story IDs in order of popularity
  """
  @spec list(atom) :: [non_neg_integer, ...]
  def list(list) when is_atom(list) do
    fetch_fixture(list)
  end

  @doc """
  Raw JSON story struct
  """
  @spec story(non_neg_integer | binary) :: map
  def story(id) when is_number(id) or is_binary(id) do
    fetch_fixture("items/#{id}")
  end

  @doc """
  Raw JSON user struct
  """
  @spec user(binary) :: map
  def user(username) when is_binary(username) do
    fetch_fixture("users/#{username}")
  end

  defp fetch_fixture(path) do
    Path.join([@fixtures_dir, "#{path}.json"])
    |> File.read!()
    |> Jason.decode!()
  end
end
