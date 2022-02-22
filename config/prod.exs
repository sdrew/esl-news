import Config

config :esl_news, :cowboy, port: String.to_integer(System.get_env("PORT", "8080"))
