import Config

config :esl_news, :cowboy, port: String.to_integer(System.get_env("PORT", "8080"))
config :esl_news, sync_items_count: 50
config :esl_news, sync_workers: 10
