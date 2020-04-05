defmodule Dissolver.Repo do
  use Ecto.Repo,
    otp_app: :dissolver,
    adapter: Ecto.Adapters.Postgres
end
