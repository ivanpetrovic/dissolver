defmodule Dissolver.PaginatorTest do
  use ExUnit.Case
  use Phoenix.ConnTest, only: [:build_conn, 0]
  alias Ecto.Adapters.SQL.Sandbox
  alias Dissolver.{Repo, Paginator}

  # TODO: spec out Paginator per its open interface. No need to expose private functions

  # import Dissolver.Paginator

  # TODO: Replace test

  setup tags do
    :ok = Sandbox.checkout(Repo)

    unless tags[:async] do
      Sandbox.mode(Repo, {:shared, self()})
    end

    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end

  test "next page only if there are more pages", %{conn: conn} do
    paginator = %{
      %Paginator{}
      | total_count: 40,
        total_pages: 4,
        per_page: 10,
        page: 1
    }

    assert Paginator.paginate(conn, paginator, next_label: "next") == [
             {"next", 2, "/?page=2", false}
           ]

    paginator = %{
      %Paginator{}
      | total_count: 40,
        total_pages: 4,
        per_page: 10,
        page: 4
    }

    assert Paginator.paginate(conn, paginator, next_label: "next") == [
             {nil, 3, "/?page=3", false}
           ]

    paginator = %{
      %Paginator{}
      | total_count: 10,
        total_pages: 1,
        per_page: 10,
        page: 1
    }

    assert Paginator.paginate(conn, paginator) == []
  end

  test "generate previous page unless first", %{conn: conn} do
    paginator = %{
      %Paginator{}
      | total_count: 40,
        total_pages: 4,
        per_page: 10,
        page: 4
    }

    assert Paginator.paginate(conn, paginator, previous_label: "previous") == [
             {"previous", 3, "/?page=3", false}
           ]

    paginator = %{
      %Paginator{}
      | total_count: 40,
        total_pages: 4,
        per_page: 10,
        page: 1
    }

    assert Paginator.paginate(conn, paginator, previous_label: "previous") == [
             {nil, 2, "/?page=2", false}
           ]

    paginator = %{
      %Paginator{}
      | total_count: 10,
        total_pages: 1,
        per_page: 10,
        page: 1
    }

    assert Paginator.paginate(conn, paginator) == []
  end

  # TODO: fix how build params are using in HTML/JSON

  # test "generate first page", %{conn: conn} do
  #   paginator = %{
  #     %Paginator{}
  #     | total_count: 100,
  #       total_pages: 10,
  #       per_page: 10,
  #       page: 9
  #   }

  #   assert Paginator.paginate(conn, paginator, first_label: "first") == []
  # end

  # TODO: Replace test
  # test "generate first page" do
  #   assert first_page([], 5, 3, true) == [{:first, 1}]
  #   assert first_page([], 5, 3, false) == []
  #   assert first_page([], 3, 3, true) == []
  # end

  # TODO: Replace test
  # test "generate last page" do
  #   assert last_page([], 5, 10, 3, true) == [{:last, 10}]
  #   assert last_page([], 5, 10, 3, false) == []
  #   assert last_page([], 5, 10, 3, false) == []
  # end

  # TODO: Replace test
  # test "encode query params" do
  #   params = [query: "foo", page: 2, per_page: 10]
  #   expected = "query=foo&page=2&per_page=10"
  #   assert build_query(params) == expected
  # end

  # TODO: Replace test
  # test "build full abs url with params" do
  #   params = [query: "foo", page: 2, per_page: 10, foo: [1, 2]]
  #   conn = %{request_path: "http://localhost:4000/products"}
  #   expected = "http://localhost:4000/products?query=foo&page=2&per_page=10&foo[]=1&foo[]=2"
  #   assert build_url(conn, params) == expected
  # end

  # TODO: Replace test
  # test "build full abs url with invalid params" do
  #   params = nil
  #   conn = %{request_path: "http://localhost:4000/products"}
  #   expected = "http://localhost:4000/products"
  #   assert build_url(conn, params) == expected
  # end
end
