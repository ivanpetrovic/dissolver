defmodule Dissolver.JSON do
  use Phoenix.HTML
  import Dissolver.Paginator, only: [build_options: 1]

  @moduledoc """
  JSON helpers to render the pagination links in json format.
  import the `Dissolver.JSON` in your view module.

      defmodule MyApp.ProductView do
        use MyApp.Web, :view
        import Dissolver.JSON

        def render("index.json", %{conn: conn, products: products, dissolver: dissolver}) do
          %{data: render_many(products, MyApp.ProductView, "product.json"),
            pagination: paginate(conn, dissolver)}
        end
      end


  Where `dissolver` is a `%Dissolver{}` struct returned from `Dissolver.paginate/2`.

  `paginate` helper takes keyword list of `options`.
    paginate(dissolver, window: 5, next_label: ">>", previous_label: "<<", first: true, last: true, first_label: "First", last_label: "Last")
  """
  def paginate(conn, paginator, opts \\ []) do
    opts = build_options(opts)

    Dissolver.Paginator.paginate(conn, paginator, opts)
    |> render_page_list()
  end

  def render_page_list(page_list) do
    Enum.map(page_list, fn {link_label, page, url, current} ->
      %{label: "#{link_label}", url: url, page: page, current: current}
    end)
  end
end
