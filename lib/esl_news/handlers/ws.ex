defmodule EslNews.Handlers.Ws do
  @moduledoc """
  `EslNews.Handlers.Ws` provides a JSON response for the latest available Stories through websockets
  Implements @behaviour for `EslNews.Websocket`
  """
  use EslNews.Websocket
  alias EslNews.Store.Story

  @ws_tick_ms 2_000

  @doc """
  Deliver JSON encoded list of stories to the websocket client every time the timer expires
  """
  @impl true
  @spec websocket_info({:timeout, any, :connected | :tick}, any) :: call_result()
  def websocket_info(call, state) do
    Logger.ws(call, state)

    list = :topstories

    stories =
      Story.all(list)
      |> Enum.slice(0, 50)
      |> Jason.encode!()

    :erlang.start_timer(@ws_tick_ms, self(), :tick)
    {[active: true, text: stories], state}
  end
end
