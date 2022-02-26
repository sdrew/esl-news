defmodule EslNews.Handlers.Story do
  @moduledoc """
  `EslNews.Handlers.Story` provides a JSON response for a single Story resource
  Implements @behaviour for `EslNews.Handler`
  """
  use EslNews.Handler
  alias EslNews.Store.Story

  @doc """
  :cowboy_rest middleware to abort a request with a 404 :not_found status if the Story ID doesn't exist
  """
  @impl true
  @spec resource_exists(:cowboy_req.req(), any) ::
          {boolean, :cowboy_req.req(), any}
          | {:stop, :cowboy_req.req(), any}
          | {switch_handler(), :cowboy_req.req(), any}
  def resource_exists(request, state) do
    Logger.request(request, state)

    id =
      Handler.request_params(request, permit: [])
      |> Map.get(:id)
      |> Handler.to_integer(0)
      |> List.wrap()
      |> Kernel.++([0])
      |> Enum.max()

    state = state ++ [id: id]

    case Story.find(id) do
      {:ok, story} ->
        state = state ++ [story: story]
        {true, request, state}

      {:not_found, _} ->
        {false, request, state}
    end
  end

  @doc """
  Endpoint of the :cowboy_rest middleware chain. Renders the Story as JSON
  """
  @impl true
  @spec response(:cowboy_req.req(), any) :: {binary, :cowboy_req.req(), any}
  def response(request, state) do
    Logger.resource(state)

    {:story, story} = List.keyfind!(state, :story, 0)
    {Jason.encode!(story), request, state}
  end
end
