defmodule DissolverTest do
  use ExUnit.Case, async: false

  alias Dissolver.{Paginator, Product, Repo}

  import Ecto.Query

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Dissolver.Repo)
  end

  defp configure_per_page() do
    Application.put_env(:dissolver, :per_page, 5)
  end

  defp configure_max_per_page() do
    Application.put_env(:dissolver, :max_per_page, 7)
  end

  defp configure_max_page() do
    Application.put_env(:dissolver, :max_page, 4)
  end

  defp configure_max_count() do
    Application.put_env(:dissolver, :max_count, 20)
  end

  defp configure_lazy() do
    Application.put_env(:dissolver, :lazy, true)
  end

  defp clean_config do
    Application.put_env(:dissolver, :per_page, nil)
    Application.put_env(:dissolver, :max_per_page, nil)
    Application.put_env(:dissolver, :max_per, nil)
    Application.put_env(:dissolver, :max_count, nil)
    Application.put_env(:dissolver, :max_page, nil)
    Application.put_env(:dissolver, :lazy, nil)
  end

  defp get_env do
    [
      per_page: Application.get_env(:dissolver, :per_page, nil),
      max_per_page: Application.get_env(:dissolver, :max_per_page, nil),
      max_per: Application.get_env(:dissolver, :max_per, nil),
      max_count: Application.get_env(:dissolver, :max_count, nil),
      max_page: Application.get_env(:dissolver, :max_page, nil),
      lazy: Application.get_env(:dissolver, :lazy, nil)
    ]
  end

  defp create_products do
    for i <- 1..30 do
      %Product{name: "Product " <> to_string(i), price: 100.00}
      |> Repo.insert!()
    end
  end

  describe "defaults" do
    test "paginate/3 should default sensability" do
      clean_config()
      {items, paginator} = Product |> Dissolver.paginate(%{})

      assert paginator.per_page == 20
      assert paginator.page == 1
      assert paginator.total_count == 30
      assert paginator.total_pages == 2
      assert paginator.theme == Dissolver.HTML.Simple

      items = items |> Enum.sort_by(& &1.id) |> Enum.map(& &1.name)
      assert items == for(i <- 1..20, do: "Product #{i}")
      clean_config()
    end
  end

  describe ":per_page" do
    test "paginate/3 can configure :per_page" do
      Application.put_env(:dissolver, :per_page, 5)
      IO.inspect({"paginate/3 can configure :per_page", get_env()})

      create_products()
      {_items, paginator} = Product |> Dissolver.paginate(%{})
      assert paginator.per_page == 5
      assert paginator.total_pages == 6
      clean_config()
    end

    test "paginate/3 can accept :per_page" do
      Application.put_env(:dissolver, :per_page, 5)
      create_products()
      {items, paginator} = Product |> Dissolver.paginate(%{}, per_page: 7)
      items = items |> Enum.sort_by(& &1.id) |> Enum.map(& &1.name)

      assert paginator.per_page == 7
      assert paginator.page == 1
      assert paginator.total_count == 30
      assert paginator.total_pages == 5
      assert items == for(i <- 1..7, do: "Product #{i}")
      clean_config()
    end

    test "paginate/3 :per_page can come from params" do
      Application.put_env(:dissolver, :per_page, 5)
      IO.inspect({"paginate/3 :per_page can come from params", get_env()})

      create_products()
      {items, paginator} = Product |> Dissolver.paginate(%{"per_page" => "7"})
      items = items |> Enum.sort_by(& &1.id) |> Enum.map(& &1.name)

      assert paginator.per_page == 7
      assert paginator.page == 1
      assert paginator.total_count == 30
      assert paginator.total_pages == 5
      assert items == for(i <- 1..7, do: "Product #{i}")
      clean_config()
    end
  end

  describe ":max_per_page" do
    test "paginate/3 can configure :max_per_page" do
      Application.put_env(:dissolver, :max_per_page, 7)
      create_products()
      {items, paginator} = Product |> Dissolver.paginate(%{"per_page" => "10"})

      assert paginator.max_per_page == 7
      assert paginator.per_page == 7
      assert paginator.page == 1
      assert paginator.total_count == 30
      assert paginator.total_pages == 5

      items = items |> Enum.sort_by(& &1.id) |> Enum.map(& &1.name)
      assert items == for(i <- 1..7, do: "Product #{i}")
      clean_config()
    end

    test "paginate/3 can accept :max_per_page" do
      Application.put_env(:dissolver, :max_per_page, 7)
      create_products()
      {items, paginator} = Product |> Dissolver.paginate(%{}, max_per_page: 6)

      assert paginator.max_per_page == 6
      assert paginator.per_page == 6
      assert paginator.page == 1
      assert paginator.total_count == 30
      assert paginator.total_pages == 5

      items = items |> Enum.sort_by(& &1.id) |> Enum.map(& &1.name)
      assert items == for(i <- 1..6, do: "Product #{i}")
      clean_config()
    end

    test "paginate/3 can constrain :max_per_page" do
      Application.put_env(:dissolver, :max_per_page, 7)
      create_products()
      {items, paginator} = Product |> Dissolver.paginate(%{"per_page" => "10"}, max_per_page: 6)

      assert paginator.max_per_page == 6
      assert paginator.per_page == 6
      assert paginator.page == 1
      assert paginator.total_count == 30
      assert paginator.total_pages == 5

      items = items |> Enum.sort_by(& &1.id) |> Enum.map(& &1.name)
      assert items == for(i <- 1..6, do: "Product #{i}")
      clean_config()
    end
  end

  describe ":max_page" do
    test "paginate/3 can configure :max_page" do
      Application.put_env(:dissolver, :max_page, 4)
      create_products()
      {_items, paginator} = Product |> Dissolver.paginate(%{}, per_page: 10)
      assert paginator.per_page == 10
      assert paginator.page == 1
      assert paginator.max_page == 3
      assert paginator.total_pages == 2
      assert paginator.total_count == 20

      clean_config()
    end

    test "paginate/3 can accept :max_page" do
      Application.put_env(:dissolver, :max_page, 4)
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
      clean_config()
    end
  end

  describe ":max_count" do
    test "paginate/3 can configure :max_count" do
      Application.put_env(:dissolver, :max_count, nil)
      create_products()
      {_items, paginator} = Product |> Dissolver.paginate(%{})

      assert paginator.total_count == 20
      on_exit(:clean_config, &clean_config/0)
    end

    test "paginate/3 can accept :max_count" do
      Application.put_env(:dissolver, :max_count, nil)
      create_products()
      {_items, paginator} = Product |> Dissolver.paginate(%{}, max_count: 20)

      assert paginator.max_count == 20
      assert paginator.total_count == 20
      clean_config()
    end
  end

  describe ":lazy" do
    test "paginate/3 can configure :lazy" do
      Application.put_env(:dissolver, :lazy, true)
      create_products()
      {query, paginator} = Product |> Dissolver.paginate(%{})
      assert query == nil
      clean_config()
    end

    test "paginate/3 can accept :lazy" do
      Application.put_env(:dissolver, :lazy, true)
      create_products()
      {query, paginator} = Product |> Dissolver.paginate(%{}, lazy: true)
      assert query == nil
      clean_config()
    end
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
