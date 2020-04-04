defmodule Dissolver.Repo do
  use Ecto.Repo,
    otp_app: :dissolver,
    adapter: Ecto.Adapters.Postgres

  use Dissolver, otp_app: :dissolver, per_page: 10
end
