defmodule EslNews.Http.Client do
  use Tesla

  plug(Tesla.Middleware.BaseUrl, "https://hacker-news.firebaseio.com/v0/")
  plug(Tesla.Middleware.JSON)

  @doc """
  Available story list names
  """
  @spec lists() :: [atom, ...]
  def lists() do
    EslNews.Store.List.lists()
  end

  @doc """
  List of story IDs in order of popularity
  """
  @spec list(atom) :: [non_neg_integer, ...]
  def list(list) when is_atom(list) do
    fetch_list(list)
  end

  @doc """
  Raw JSON story struct
  """
  @spec story(non_neg_integer | binary) :: map
  def story(id) when is_number(id) or is_binary(id) do
    fetch_item("item/#{id}")
  end

  @doc """
  Raw JSON user struct
  """
  @spec user(binary) :: map
  def user(username) when is_binary(username) do
    fetch_item("user/#{username}")
  end

  defp fetch_item(path) do
    case get("#{path}.json") do
      {:ok, resp} ->
        resp.body

      _ ->
        %{}
    end
  end

  defp fetch_list(list) do
    case get("#{list}.json") do
      {:ok, resp} ->
        resp.body

      _ ->
        []
    end
  end
end
