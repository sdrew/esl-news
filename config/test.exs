import Config

config :esl_news, :cowboy, port: 8081
config :esl_news, http_client: EslNews.Http.MockClient
config :esl_news, sync_items_count: 10
config :esl_news, sync_workers: 1
