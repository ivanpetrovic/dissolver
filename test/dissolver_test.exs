defmodule DissolverTest do
  use ExUnit.Case

  alias Dissolver.{Paginator, Product, Repo}

  import Ecto.Query

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Dissolver.Repo)
  end

  def configure_env(conn) do
    Application.put_env(:dissolver, :per_page, 5)
    Application.put_env(:dissolver, :max_per_page, 10)
    {:ok, conn}
  end

  def clean_config do
    Application.put_env(:dissolver, :per_page, nil)
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

      items = items |> Enum.sort_by(& &1.id) |> Enum.map(& &1.name)
      assert items == for(i <- 1..20, do: "Product #{i}")
    end
  end

  describe ":per_page" do
    setup [:configure_env]

    test "paginate/3 can configure :per_page" do
      create_products()
      {_items, paginator} = Product |> Dissolver.paginate(%{})
      assert paginator.per_page == 5
      assert paginator.total_pages == 6
      on_exit(:clean_config, &clean_config/0)
    end

    test "paginate/3 can accept :per_page" do
      create_products()
      {items, paginator} = Product |> Dissolver.paginate(%{}, per_page: 5)
      items = items |> Enum.sort_by(& &1.id) |> Enum.map(& &1.name)

      assert paginator.per_page == 5
      assert paginator.page == 1
      assert paginator.total_count == 30
      assert paginator.total_pages == 6
      assert items == for(i <- 1..5, do: "Product #{i}")
      on_exit(:clean_config, &clean_config/0)
    end

    test "paginate/3 :per_page can come from params " do
      # TODO: configure per_page: 5
      create_products()
      {_items, paginator} = Product |> Dissolver.paginate(%{"per_page" => "5"}, per_page: 10)
      assert paginator.per_page == 5
      assert paginator.total_pages == 6
      on_exit(:clean_config, &clean_config/0)
    end

    test "paginate/3 :per_page params can't exceed otpions" do
      # TODO: configure per_page: 5
      create_products()
      {_items, paginator} = Product |> Dissolver.paginate(%{"per_page" => "11"}, per_page: 10)
      assert paginator.per_page == 10
      assert paginator.total_pages == 3
      on_exit(:clean_config, &clean_config/0)
    end
  end

  describe ":max_per_page" do
    setup [:configure_env]

    test "paginate/3 can configure :max_per_page" do
      create_products()
      {items, paginator} = Product |> Dissolver.paginate(%{"per_page" => "10"})

      assert paginator.per_page == 5
      assert paginator.page == 1
      assert paginator.total_count == 30
      assert paginator.total_pages == 6

      items = items |> Enum.sort_by(& &1.id) |> Enum.map(& &1.name)
      assert items == for(i <- 1..5, do: "Product #{i}")
    end

    test "paginate/3 can accept :max_per_page" do
      create_products()
      {items, paginator} = Product |> Dissolver.paginate(%{"per_page" => "10"}, max_per_page: 7)

      assert paginator.per_page == 7
      assert paginator.page == 1
      assert paginator.total_count == 30
      assert paginator.total_pages == 5

      items = items |> Enum.sort_by(& &1.id) |> Enum.map(& &1.name)
      assert items == for(i <- 1..5, do: "Product #{i}")
    end
  end

  describe ":max_page" do
    setup [:configure_env]

    test "paginate/3 can configure :max_page" do
      create_products()
      {_items, paginator} = Product |> Dissolver.paginate(%{})
      assert paginator.max_page == 2
      assert paginator.total_pages == 20

      on_exit(:clean_config, &clean_config/0)
    end

    test "paginate/3 can accept :max_page" do
      create_products()
      {items, paginator} = Product |> Dissolver.paginate(%{"page" => "10"}, max_page: 2)

      assert paginator.per_page == 10
      assert paginator.page == 2
      assert paginator.total_count == 20
      assert paginator.total_pages == 2

      items = items |> Enum.sort_by(& &1.id) |> Enum.map(& &1.name)
      assert items == for(i <- 1..20, do: "Product #{i}")
    end
  end

  describe ":max_count" do
    setup [:configure_env]

    test "paginate/3 can configure :max_count" do
      create_products()
      {_items, paginator} = Product |> Dissolver.paginate(%{})

      assert paginator.per_page == 5
      on_exit(:clean_config, &clean_config/0)
    end

    test "paginate/3 can accept :max_count" do
      create_products()
      {_items, paginator} = Product |> Dissolver.paginate(%{}, max_count: 20)

      assert paginator.max_count == 20
      assert paginator.total_count == 20
      on_exit(:clean_config, &clean_config/0)
    end
  end

  describe ":lazy" do
    test "paginate/3 can configure :lazy" do
      create_products()
      {query, paginator} = Product |> Dissolver.paginate(%{})
      assert query == nil
    end

    test "paginate/3 can accept :lazy" do
      create_products()
      {query, paginator} = Product |> Dissolver.paginate(%{}, lazy: true)
      assert query == nil
    end
  end

  test "non schema based queries" do
    create_products()

    query =
      from(p in "products",
        select: %{id: p.id, name: p.name}
      )

    {_items, dissolver} = Dissolver.paginate(query, %{})
    assert dissolver.total_count == 15
  end

  test "group_by in query" do
    create_products()
    {_items, dissolver} = Product |> group_by([p], p.id) |> Dissolver.paginate(%{})
    assert dissolver.total_count == 15
  end
end
