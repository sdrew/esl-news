defmodule EslNews.Handlers.Story do
  @moduledoc """
  `EslNews.Handlers.Story` provides a JSON response for a single Story resource
  Implements @behaviour for `EslNews.Handler`
  """
  use EslNews.Handler

  @impl true
  @spec response(:cowboy_req.req(), any) :: {binary, :cowboy_req.req(), any}
  def response(request, state) do
    Logger.request(request, state)

    params = Handler.request_params(request, permit: [])

    {Jason.encode!(params), request, state}
  end
end
