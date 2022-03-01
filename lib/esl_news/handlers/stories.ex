defmodule EslNews.Handlers.Stories do
  @moduledoc """
  `EslNews.Handlers.Stories` provides a JSON response for the latest available Stories.
  Implements `@behaviour` for `EslNews.Handler`
  """
  use EslNews.Handler
  alias EslNews.Store.Story

  @doc """
  Endpoint of the :cowboy_rest middleware chain. Renders the Stories list as JSON
  """
  @impl true
  @spec response(:cowboy_req.req(), any) :: {binary, :cowboy_req.req(), any}
  def response(request, state) do
    Logger.request(request, state)

    {page, per} = Handler.pagination_params(request)
    offset = (page - 1) * per

    list = :topstories

    stories =
      Story.all(list)
      |> Enum.slice(offset, per)

    {Jason.encode!(stories), request, state}
  end
end
