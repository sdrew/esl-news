import Config

config :esl_news, :cowboy, port: 8081
config :esl_news, http_client: EslNews.Http.MockClient
