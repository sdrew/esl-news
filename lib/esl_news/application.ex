defmodule EslNews.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Starts a worker by calling: EslNews.Worker.start_link(arg)
      # {EslNews.Worker, arg}
    ]

    ranch_opts = Application.fetch_env!(:esl_news, :cowboy)

    {:ok, _} =
      :cowboy.start_clear(:http, ranch_opts, %{env: %{dispatch: EslNews.Router.dispatch()}})

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: EslNews.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
