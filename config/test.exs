use Mix.Config

config :dissolver, ecto_repos: [Dissolver.Repo]

config :dissolver, Dissolver.Repo,
  username: "postgres",
  password: "postgres",
  database: "dissolver_dev",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

# shut up only log errors
config :logger, :console, level: :error
