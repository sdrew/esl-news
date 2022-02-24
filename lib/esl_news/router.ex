defmodule EslNews.Router do
  alias EslNews.Handlers

  @spec dispatch :: :cowboy_router.dispatch_rules()
  def dispatch() do
    :cowboy_router.compile([{:_, routes()}])
  end

  @spec routes :: [:cowboy_router.route_path(), ...]
  def routes() do
    [
      {"/api/stories", Handlers.Stories, []},
      {"/api/stories/:id", Handlers.Story, []},
      {"/", :cowboy_static, {:priv_file, :esl_news, "index.html", [{:charset, "utf-8"}]}},
      {"/static/[...]", :cowboy_static, {:priv_dir, :esl_news, "static", [{:charset, "utf-8"}]}}
    ]
  end
end
