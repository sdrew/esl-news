defmodule EslNews.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @sync_workers Application.compile_env(:esl_news, :sync_workers, 4)

  @doc """
  Supervisor children specs.
  - Always run Store.Schema
  - Avoid running other children in :test environment.
  """
  @spec children(atom) :: [{module, [keyword, ...]}, ...]
  def children(:test), do: children(:all) |> Enum.slice(0, 1)

  def children(_) do
    sync_workers =
      for i <- 1..@sync_workers do
        Supervisor.child_spec(
          {EslNews.Http.SyncItems, [name: String.to_atom("EslNews.Http.SyncItems.#{i}")]},
          id: String.to_atom("sync_items_#{i}")
        )
      end

    [
      # Starts a worker by calling: EslNews.Worker.start_link(arg)
      # {EslNews.Store.Schema, arg} must always be first
      {EslNews.Store.Schema, [name: EslNews.Store.Schema]},
      {EslNews.Http.SyncLists, [name: EslNews.Http.SyncLists]}
    ] ++ sync_workers
  end

  @impl true
  def start(_type, _args) do
    env = Application.fetch_env!(:esl_news, :env)
    ranch_opts = Application.fetch_env!(:esl_news, :cowboy)

    {:ok, _} =
      :cowboy.start_clear(:http, ranch_opts, %{env: %{dispatch: EslNews.Router.dispatch()}})

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: EslNews.Supervisor]
    Supervisor.start_link(children(env), opts)
  end
end
