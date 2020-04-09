defmodule DissolverTest do
  use ExUnit.Case, async: false

  alias Dissolver.{Product, Repo}

  import Ecto.Query

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Dissolver.Repo)
    on_exit(:clean_config, &clean_config/0)
  end

  defp configure_per_page(conn) do
    Application.put_env(:dissolver, :per_page, 5)
    {:ok, conn}
  end

  defp configure_max_per_page(conn) do
    Application.put_env(:dissolver, :max_per_page, 7)
    {:ok, conn}
  end

  defp configure_max_page(conn) do
    Application.put_env(:dissolver, :max_page, 4)
    {:ok, conn}
  end

  defp configure_max_count(conn) do
    Application.put_env(:dissolver, :max_count, 40)
    {:ok, conn}
  end

  defp configure_lazy(conn) do
    Application.put_env(:dissolver, :lazy, true)
    {:ok, conn}
  end

  defp clean_config do
    Application.put_env(:dissolver, :per_page, nil)
    Application.put_env(:dissolver, :max_per_page, nil)
    Application.put_env(:dissolver, :max_per, nil)
    Application.put_env(:dissolver, :max_count, nil)
    Application.put_env(:dissolver, :max_page, nil)
    Application.put_env(:dissolver, :lazy, nil)
  end

  defp create_products do
    for i <- 1..30 do
      %Product{name: "Product " <> to_string(i), price: 100.00}
      |> Repo.insert!()
    end
  end

  describe "defaults" do
    test "paginate/3 should default sensability" do
      create_products()
      {items, paginator} = Product |> Dissolver.paginate(%{})

      assert paginator.per_page == 20
      assert paginator.page == 1
      assert paginator.total_count == 30
      assert paginator.total_pages == 2
      assert paginator.theme == Dissolver.HTML.Simple
      assert paginator.params == %{}

      items = items |> Enum.sort_by(& &1.id) |> Enum.map(& &1.name)
      assert items == for(i <- 1..20, do: "Product #{i}")
      clean_config()
    end
  end

  describe ":per_page" do
    setup [:configure_per_page]

    test "paginate/3 can configure :per_page" do
      create_products()
      {_items, paginator} = Product |> Dissolver.paginate(%{})
      assert paginator.per_page == 5
      assert paginator.total_pages == 6
    end

    test "paginate/3 can accept :per_page" do
      create_products()
      {items, paginator} = Product |> Dissolver.paginate(%{}, per_page: 7)
      items = items |> Enum.sort_by(& &1.id) |> Enum.map(& &1.name)

      assert paginator.per_page == 7
      assert paginator.page == 1
      assert paginator.total_count == 30
      assert paginator.total_pages == 5
      assert items == for(i <- 1..7, do: "Product #{i}")
    end

    test "paginate/3 :per_page can come from params" do
      create_products()
      {items, paginator} = Product |> Dissolver.paginate(%{"per_page" => "7"})
      items = items |> Enum.sort_by(& &1.id) |> Enum.map(& &1.name)

      assert paginator.per_page == 7
      assert paginator.page == 1
      assert paginator.total_count == 30
      assert paginator.total_pages == 5
      assert items == for(i <- 1..7, do: "Product #{i}")
    end
  end

  describe ":max_per_page" do
    setup [:configure_max_per_page]

    test "paginate/3 can configure :max_per_page" do
      create_products()
      {items, paginator} = Product |> Dissolver.paginate(%{"per_page" => "10"})

      assert paginator.max_per_page == 7
      assert paginator.per_page == 7
      assert paginator.page == 1
      assert paginator.total_count == 30
      assert paginator.total_pages == 4

      items = items |> Enum.sort_by(& &1.id) |> Enum.map(& &1.name)
      assert items == for(i <- 1..7, do: "Product #{i}")
    end

    test "paginate/3 can accept :max_per_page" do
      create_products()
      {items, paginator} = Product |> Dissolver.paginate(%{}, max_per_page: 6)

      assert paginator.max_per_page == 6
      assert paginator.per_page == 6
      assert paginator.page == 1
      assert paginator.total_count == 30
      assert paginator.total_pages == 5

      items = items |> Enum.sort_by(& &1.id) |> Enum.map(& &1.name)
      assert items == for(i <- 1..6, do: "Product #{i}")
    end

    test "paginate/3 can constrain :max_per_page" do
      create_products()
      {items, paginator} = Product |> Dissolver.paginate(%{"per_page" => "10"}, max_per_page: 6)

      assert paginator.max_per_page == 6
      assert paginator.per_page == 6
      assert paginator.page == 1
      assert paginator.total_count == 30
      assert paginator.total_pages == 5

      items = items |> Enum.sort_by(& &1.id) |> Enum.map(& &1.name)
      assert items == for(i <- 1..6, do: "Product #{i}")
    end
  end

  describe ":max_page" do
    setup [:configure_max_page]

    test "paginate/3 can configure :max_page" do
      create_products()
      {_items, paginator} = Product |> Dissolver.paginate(%{}, per_page: 10, max_per_page: 30)
      assert paginator.per_page == 10
      assert paginator.page == 1
      assert paginator.max_page == 3
      assert paginator.total_pages == 3
      assert paginator.total_count == 30
    end

    test "paginate/3 can accept :max_page" do
      create_products()

      {items, paginator} =
        Product |> Dissolver.paginate(%{"page" => "10"}, max_page: 2, per_page: 10)

      assert paginator.per_page == 10
      assert paginator.page == 2
      assert paginator.max_page == 2
      assert paginator.total_count == 20
      assert paginator.total_pages == 2

      items = items |> Enum.sort_by(& &1.id) |> Enum.map(& &1.name)
      assert items == for(i <- 11..20, do: "Product #{i}")
    end
  end

  describe ":max_count" do
    setup [:configure_max_count]

    test "paginate/3 can configure :max_count" do
      create_products()
      {_items, paginator} = Product |> Dissolver.paginate(%{})

      assert paginator.total_count == 30
    end

    test "paginate/3 can accept :max_count" do
      create_products()
      {_items, paginator} = Product |> Dissolver.paginate(%{}, max_count: 20)

      assert paginator.max_count == 20
      assert paginator.total_count == 20
    end

    test "paginate/3 can constain :max_count" do
      create_products()
      {_items, paginator} = Product |> Dissolver.paginate(%{"page" => "3"}, max_count: 20)

      assert paginator.max_count == 20
      assert paginator.total_count == 20
      assert paginator.page == 2
      assert paginator.total_pages == 2
    end
  end

  describe ":lazy" do
    setup [:configure_lazy]

    test "paginate/3 can configure :lazy" do
      create_products()
      {query, _paginator} = Product |> Dissolver.paginate(%{})
      refute is_list(query)
      assert is_map(query)
    end

    test "paginate/3 can accept :lazy" do
      create_products()
      {query, _paginator} = Product |> Dissolver.paginate(%{}, lazy: true)
      refute is_list(query)
      assert is_map(query)
    end
  end

  test "paginate/3 can accept :total_count" do
    create_products()
    {_items, %{total_count: total_count}} = Product |> Dissolver.paginate(%{}, total_count: 10)
    assert total_count == 10
  end

  test "non schema based queries" do
    clean_config()
    create_products()

    query =
      from(p in "products",
        select: %{id: p.id, name: p.name}
      )

    {_items, dissolver} = Dissolver.paginate(query, %{})
    assert dissolver.total_count == 30
    clean_config()
  end

  test "group_by in query" do
    clean_config()
    create_products()
    {_items, dissolver} = Product |> group_by([p], p.id) |> Dissolver.paginate(%{})
    assert dissolver.total_count == 30
    clean_config()
  end
end
