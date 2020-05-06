defmodule Dissolver.HTML do
  use Phoenix.HTML
  alias Dissolver.Paginator

  @moduledoc """
  An Html helper to render the pagination links,

  Start by importing the `Dissolver.HTML` in your view module.

  ```
  defmodule MyApp.ProductView do
    use MyApp.Web, :view
    import Dissolver.HTML
  end
  ```



  now you have the `paginate/2` view helper in your template file.
  ```
  <%= paginate @conn, @paginator %>
  ```

  Where `@page` is a `%Dissolver.Paginator{}` struct returned from `Dissolver.paginate/2`.

  `paginate` helper takes keyword list of `options` and `params`.
    <%= paginate @conn, @page, window: 5, next_label: ">>", previous_label: "<<", first: true, last: true, first_label: "First", last_label: "Last" %>
  """

  @doc """
  Generates the HTML pagination links for a given page returned by Dissolver.

  Example:

      iex> Dissolver.HTML.paginate(@conn, @dissolver)

  Path can be overriden by adding setting `:path` in the `opts`.
  For example:

      Dissolver.HTML.paginate(@conn, @dissolver, path: product_path(@conn, :index, foo: "bar"))

  Additional panigation class can be added by adding setting `:class` in the `opts`.
  For example:

      Dissolver.HTML.paginate(@conn, @dissolver, theme: :boostrap4, class: "paginate-sm")
  """

  def paginate(socket, paginator, route_helper, action, opts \\ []) do
    opts = Paginator.build_options(opts)

    Paginator.paginate(socket, paginator, route_helper, action, opts)
    |> render_page_list(opts)
  end

  def paginate(conn, paginator, opts \\ []) do
    opts = Paginator.build_options(opts)

    conn
    |> Paginator.paginate(paginator, opts)
    |> render_page_list(opts)
  end

  defp render_page_list(page_list, opts) do
    opts[:theme].generate_links(page_list, opts[:class])
  end
end
