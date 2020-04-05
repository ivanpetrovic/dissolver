defmodule DissolverTest do
  use ExUnit.Case

  alias Dissolver.Product
  alias Dissolver.Repo

  import Ecto.Query

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Dissolver.Repo)
  end

  defp create_products do
    for i <- 1..15 do
      %Product{name: "Product " <> to_string(i), price: 100.00}
      |> Repo.insert!()
    end
  end

  test "offset works correctly" do
    create_products()
    {items, _dissolver} = Product |> Repo.paginate(%{"page" => 2}, per_page: 5)
    items = items |> Enum.sort_by(& &1.id) |> Enum.map(& &1.name)

    assert ["Product 6", "Product 7", "Product 8", "Product 9", "Product 10"] == items
  end

  test "non schema based queries" do
    create_products()

    query =
      from(p in "products",
        select: %{id: p.id, name: p.name}
      )

    {_items, dissolver} = Repo.paginate(query, %{})
    assert dissolver.total_count == 15
  end

  test "group_by in query" do
    create_products()
    {_items, dissolver} = Product |> group_by([p], p.id) |> Repo.paginate(%{})
    assert dissolver.total_count == 15
  end

  test "per_page option" do
    create_products()
    {_items, dissolver} = Product |> Repo.paginate(%{}, per_page: 5)
    assert dissolver.per_page == 5
  end

  test "default per_page option" do
    create_products()
    {items, dissolver} = Product |> Repo.paginate(%{}, per_page: nil)
    assert length(items) == 10
    assert dissolver.total_pages == 2
    assert dissolver.total_count == 15
    assert dissolver.per_page == 10
  end

  test "total pages based on per_page" do
    create_products()
    {_items, dissolver} = Product |> Repo.paginate(%{}, per_page: 5)
    assert dissolver.total_pages == 3
  end

  test "default config" do
    create_products()
    {items, dissolver} = Product |> Repo.paginate(%{})
    assert dissolver.total_pages == 2
    assert dissolver.page == 1
    assert length(items) == 10
  end

  # Function should be private better tests are needed.
  # test "total_pages calculation" do
  #   row_count = 100
  #   per_page = 10
  #   total_pages = 10
  #   assert Dissolver.get_total_pages(row_count, per_page) == total_pages
  # end

  test "total_count option" do
    create_products()
    {_items, dissolver} = Product |> Repo.paginate(%{}, total_count: 3, per_page: 5)
    assert dissolver.total_count == 3
    assert dissolver.total_pages == 1
  end

  # This is needs to be better
  # I'd expect that if you have 100 page that if you set the max page to 10
  # if you try to go to any page byond 10 you always stop at 10.
  # Also if you try to got to a page that is greater than the total pages it would end up on
  # the total pages. IE:
  # total_pages:  5, max_page = 10, params: %{page: 100} = current_page: 5
  # or
  # total_pages: 100, max_page: 10, params: %{page: 100} = current_page: 10
  test "max_page constraint" do
    false
    # create_products()

    # {_items, dissolver} =
    #   Product |> Repo.paginate(%{"page" => 100}, total_count: 3, per_page: 5, max_page: 10)

    # assert dissolver.total_count == 3
    # assert dissolver.total_pages == 1
    # assert dissolver.page == 1
  end

  test "use count query when provided total_count is nil" do
    create_products()
    {_items, dissolver} = Product |> Repo.paginate(%{}, total_count: nil, per_page: 5)
    assert dissolver.total_count == 15
    assert dissolver.total_pages == 3
  end

  # Function should be private better tests are needed.
  # test "to_integer returns number" do
  #   assert Dissolver.to_integer(10) == 10
  #   assert Dissolver.to_integer("10") == 10
  #   assert Dissolver.to_integer(nil) == 1
  # end
end
