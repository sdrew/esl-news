defmodule EslNews.Router do
  @moduledoc """
  `EslNews.Router` defines the routes and handlers required to generate the `:cowboy_router.dispatch_rules()`
  required by the `:cowboy` webserver.
  """
  alias EslNews.Handlers

  @doc """
  Compile routes and return `:cowboy_router.dispatch_rules()`
  """
  @spec dispatch :: :cowboy_router.dispatch_rules()
  def dispatch() do
    :cowboy_router.compile([{:_, routes()}])
  end

  @doc """
  Define routes and handler modules.
  """
  @spec routes :: [:cowboy_router.route_path(), ...]
  def routes() do
    charset = {:charset, "utf-8"}

    [
      {"/api/stories", Handlers.Stories, [charset]},
      {"/api/stories/:id", Handlers.Story, [charset]},
      {"/api/ws", Handlers.Ws, [charset]},
      {"/", :cowboy_static, {:priv_file, :esl_news, "index.html", [charset]}},
      {"/static/[...]", :cowboy_static, {:priv_dir, :esl_news, "static", [charset]}}
    ]
  end
end
