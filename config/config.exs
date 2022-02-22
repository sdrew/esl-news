import Config

config :esl_news, env: config_env()

import_config("#{config_env()}.exs")
