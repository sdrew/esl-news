defmodule EslNews.Handlers.Stories do
  @moduledoc """
  `EslNews.Handlers.Stories` provides a JSON response for the latest available Stories
  Implements @behaviour for `EslNews.Handler`
  """
  use EslNews.Handler

  @impl true
  @spec response(:cowboy_req.req(), any) :: {binary, :cowboy_req.req(), any}
  def response(request, state) do
    Logger.request(request, state)

    params = Handler.request_params(request, permit: [:page, :per])

    {Jason.encode!(params), request, state}
  end
end
