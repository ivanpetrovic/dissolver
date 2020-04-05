defmodule Dissolver.Query do
  import Ecto.Query

  @spec limit(Ecto.Query.t()) :: Ecto.Query.t()
  def limit(query) do
    from(q in query, limit: 0)
  end

  @spec offset(Ecto.Query.t()) :: Ecto.Query.t()
  def offset(query) do
    from(q in query, offset: 0)
  end
end
