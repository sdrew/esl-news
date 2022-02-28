defmodule EslNews.Router do
  alias EslNews.Handlers

  @spec dispatch :: :cowboy_router.dispatch_rules()
  def dispatch() do
    :cowboy_router.compile([{:_, routes()}])
  end

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
