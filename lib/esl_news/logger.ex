require Logger

defmodule EslNews.Logger do
  @moduledoc """
  `EslNews.Logger` provides logging helpers for `EslNews.Handlers`
  """

  @doc """
  Log a `:cowboy_req` with a timestamp, method, path and optionally the query params
  """
  @spec request(:cowboy_req.req(), any) :: :ok
  def request(request, _state) do
    method = :cowboy_req.method(request)
    path = request_path(:cowboy_req.path(request), :cowboy_req.qs(request))

    Logger.info("#{method} #{path}")
  end

  defp request_path(path, ""), do: path
  defp request_path(path, qs), do: "#{path}?#{qs}"
end
