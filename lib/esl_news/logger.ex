require Logger

defmodule EslNews.Logger do
  @moduledoc """
  `EslNews.Logger` provides logging helpers for `EslNews.Handlers`
  """

  @should_log Application.fetch_env!(:esl_news, :env) != :test

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

  defp request_path(path, ""), do: path
  defp request_path(path, qs), do: "#{path}?#{qs}"
end
