import Config

config :esl_news, env: config_env()
config :esl_news, http_client: EslNews.Http.Client

config :tesla, adapter: Tesla.Adapter.Hackney

import_config("#{config_env()}.exs")
