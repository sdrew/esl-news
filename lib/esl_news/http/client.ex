defmodule EslNews.Http.Client do
  use Tesla

  plug(Tesla.Middleware.BaseUrl, "https://hacker-news.firebaseio.com/v0/")
  plug(Tesla.Middleware.JSON)

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

  @spec list(atom) :: [non_neg_integer, ...]
  def list(list) when is_atom(list) do
    fetch_list(list)
  end

  @spec story(non_neg_integer | binary) :: map
  def story(id) when is_number(id) or is_binary(id) do
    fetch_item("item/#{id}")
  end

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
