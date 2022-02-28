defmodule EslNews.Handlers.Ws do
  @moduledoc """
  `EslNews.Handlers.Ws` provides a JSON response for the latest available Stories through websockets
  Implements @behaviour for `EslNews.Websocket`
  """
  use EslNews.Websocket
  alias EslNews.Store.Story

  @ws_tick_ms 20_000
  @ws_empty_tick_ms 5_000

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

    tick_ms =
      stories
      |> Enum.count()
      |> case do
        0 ->
          # Faster updates when stories is empty (eg. on server start)
          @ws_empty_tick_ms

        _ ->
          @ws_tick_ms
      end

    :erlang.start_timer(tick_ms, self(), :tick)

    {
      [
        active: true,
        text:
          stories
          |> Jason.encode!()
      ],
      state
    }
  end
end
