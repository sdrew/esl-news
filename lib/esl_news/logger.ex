require Logger

defmodule EslNews.Logger do
  @moduledoc """
  `EslNews.Logger` provides logging helpers for `EslNews.Handlers`
  """

  @should_log Application.compile_env!(:esl_news, :env) != :test

  @doc """
  Log a simple value with timestamp
  """
  def info(info) do
    if @should_log, do: Logger.info("#{info}")
  end

  @doc """
  Log a `:cowboy_req` with a timestamp, method, path and optionally the query params
  """
  @spec request(:cowboy_req.req(), any) :: :ok
  def request(request, _state) do
    method = :cowboy_req.method(request)
    path = request_path(:cowboy_req.path(request), :cowboy_req.qs(request))

    if @should_log, do: Logger.info("#{method} #{path}")
  end

  @doc """
  Log the Story in a request state with a timestamp, the Story ID and title
  """
  @spec resource([Keyword.t()]) :: :ok
  def resource(state) do
    {:id, id} = List.keyfind!(state, :id, 0)
    {:story, story} = List.keyfind!(state, :story, 0)

    if @should_log, do: Logger.info("Rendered Story ##{id} - #{story.title}")
  end

  @doc """
  Log a `:cowboy_websocket` callback with a timestamp, frame data, and state
  """
  @spec ws(tuple, list) :: :ok | nil
  def ws(call, state) do
    ws_frame(call)
    ws_state(state)
  end

  @doc """
  Log a `:cowboy_websocket` frame
  """
  @spec ws_frame(tuple) :: :ok | nil
  def ws_frame({:timeout, _timer, message}) do
    if @should_log, do: Logger.info("WS Frame [timeout] - #{message}")
  end

  def ws_frame({key, value}) do
    if @should_log, do: Logger.info("WS Frame [#{key}] - #{value}")
  end

  @doc """
  Log a `:cowboy_websocket` state
  """
  @spec ws_state(list) :: :ok | nil
  def ws_state(state) do
    if @should_log do
      state
      |> Enum.each(fn {key, value} ->
        Logger.info("WS State [#{key}] - #{Jason.encode!(value)}")
      end)
    end
  end

  defp request_path(path, ""), do: path
  defp request_path(path, qs), do: "#{path}?#{qs}"
end
