defmodule Dissolver do
  @moduledoc """
  Pagination for Ecto and Phoenix.

  Dissolver is the continuation and fork of the fine work [kerosene](https://github.com/elixirdrops/kerosene)
  Out of respect to the authors of kerosene I won't be publishing this on https://hex.pm/
  untill and if this becomes the replacement for kerosene.

  Until then you will need to install this from github.

  ## Installation
  add Dissolver to your mix.exs dependencies:
  ```
  def deps do
    [
      {:dissolver, github: 'MorphicPro/dissolver'}
    ]
  end
  ```

  Next provide Dissolver your Repo module via the config.
  Add the following to your config:
  ```

  ...
  config :dissolver,
    repo: MyApp.Repo
    per_page: 2

  import_config "\#{Mix.env()}.exs"
  ```
  For more information about the configuration options look at the [Configurations](#module-configuration) section

  Now you are ready to start using Dissolver.

  ## Usage
  Start paginating your queries
  ```
  def index(conn, params) do
    {products, paginator} =
    Product
    |> Product.with_lowest_price
    |> Dissolver.paginate(params)

    render(conn, "index.html", products: products, paginator: paginator)
  end
  ```

  Add the view helper to your view
  ```
  defmodule MyApp.ProductView do
    use MyApp.Web, :view
    import Dissolver.HTML
  end
  ```

  Generate the links using the view helper in your template
  ```elixir
  <%= paginate @conn, @paginator %>
  ```

  Importing `Dissolver.HTML` provides your template access
  to `Dissolver.HTML.paginate/3` as the prior example shows.
  The `Dissolver.HTML.paginate/3` can take a host of options to aid
  the theme from how many links to show (`window: integer`) to what the
  link labels should read.

  By default the theme used to generate the html is the `Dissolver.HTML.Simple` theme.
  It will only provide the very basic prev|next buttons. For more theme options, including providing
  your own, read the following [Configurations](#module-configuration)

  ## Configuration

  This module uses the following that can be set as globals in your `config/config.ex` configurations
  * `:repo` - _*Required*_ Your app's Ecto Repo
  * `:theme` (default: `Dissolver.HTML.Simple`) - A module that implements the `Dissolver.HTML.Theme` behavior
      There are a few pre defiend theme modules found in `dessolver/html/`
      * `Dissolver.HTML.Simple` - This is the _default_ with only previous | next links
      * `Dissolver.HTML.Bootstrap` - [A Bootstrap 4 theme ](https://getbootstrap.com/)
      * `Dissolver.HTML.Foundation` - [A Foundation theme](https://get.foundation/)
      * `Dissolver.HTML.Materialize` - [A Materialize theme](https://materializecss.com/)
      * `Dissolver.HTML.Semantic` - [A Semantic UI theme](https://semantic-ui.com/)
      * `Dissolver.HTML.Tailwind` - [A Tailwind CSS theme](https://tailwindcss.com/)

  * `:per_page` (default: 10) - The global per page setting
  * `:max_page` - The limit of pages allow to navigate regardless of total pages found
      This option is ignored if not provided and defaults to total pages found in the query.
  * `:lazy` (default: false) - This option if enabled will result in all `Dissolver.paginate/3` calls
      return an Ecto.Query rather than call Repo.all. This is useful for when you need to paginate
      on an association via a preload. TODO: provide example.
  ##
  """

  import Ecto.Query

  alias Dissolver.Paginator

  @spec paginate(Ecto.Query.t(), map(), nil | keyword()) :: {list(), Paginator.t()}
  def paginate(query, params, opts \\ []) do
    repo = Application.fetch_env!(:dissolver, :repo)

    process_options(opts)
    |> process_params(params)
    |> put_total_count(repo, query)
    |> put_total_pages()
    |> max_per_page_constraint()
    |> max_page_constraint()
    |> max_count_constraint()
    |> page_constraint()
    |> process_query(query)
    |> return_query_results(repo)
  end

  defp process_options(opts) do
    app_config =
      %{
        per_page: Application.get_env(:dissolver, :per_page),
        max_per_page: Application.get_env(:dissolver, :max_per_page),
        max_page: Application.get_env(:dissolver, :max_page),
        max_count: Application.get_env(:dissolver, :max_count),
        lazy: Application.get_env(:dissolver, :lazy)
      }
      |> drop_nil()

    opts_map =
      %{
        per_page: Keyword.get(opts, :per_page),
        max_per_page: Keyword.get(opts, :max_per_page),
        max_page: Keyword.get(opts, :max_page),
        max_count: Keyword.get(opts, :max_count),
        lazy: Keyword.get(opts, :lazy)
      }
      |> drop_nil()

    parsed_opts = Map.merge(app_config, opts_map)

    struct(Dissolver.Paginator, parsed_opts)
  end

  # TODO: Add total_count as option
  defp process_params(paginator, params) do
    paginator
    |> Map.merge(process_page_param(params))
    |> Map.merge(process_per_page_param(params))
  end

  defp process_page_param(%{"page" => page}) do
    %{page: String.to_integer(page)}
  end

  defp process_page_param(_params), do: %{}

  defp process_per_page_param(%{"per_page" => per_page}) do
    %{per_page: String.to_integer(per_page)}
  end

  defp process_per_page_param(_params), do: %{}

  # TODO: refactor
  defp put_total_count(paginator, repo, query) do
    %{paginator | total_count: get_total_count(repo, query)}
  end

  defp get_total_count(repo, query) do
    query
    |> exclude(:preload)
    |> exclude(:order_by)
    |> total_count()
    |> repo.one()
  end

  defp put_total_pages(%{total_count: total_count, per_page: per_page} = paginator) do
    %{paginator | total_pages: get_total_pages(total_count, per_page)}
  end

  defp get_total_pages(_, nil), do: 1

  defp get_total_pages(count, per_page) do
    Float.ceil(count / per_page) |> trunc()
  end

  defp max_per_page_constraint(%{per_page: per_page, max_per_page: nil} = paginator) do
    %{paginator | max_per_page: per_page}
  end

  defp max_per_page_constraint(
         %{total_count: total_count, per_page: per_page, max_per_page: max_per_page} = paginator
       )
       when per_page > max_per_page do
    %{
      paginator
      | per_page: max_per_page,
        total_pages: (total_count / max_per_page) |> trunc |> abs
    }
  end

  defp max_per_page_constraint(paginator), do: paginator

  defp max_page_constraint(%{max_page: nil, total_pages: total_pages} = paginator) do
    %{paginator | max_page: total_pages}
  end

  defp max_page_constraint(%{max_page: max_page, total_pages: total_pages} = paginator)
       when max_page >
              total_pages do
    %{paginator | max_page: total_pages}
  end

  defp max_page_constraint(
         %{
           per_page: per_page,
           max_page: max_page
         } = paginator
       ) do
    %{
      paginator
      | total_pages: max_page,
        total_count: max_page * per_page
    }
  end

  defp max_count_constraint(%{max_count: nil} = paginator), do: paginator

  defp max_count_constraint(%{total_count: total_count, max_count: max_count} = paginator)
       when total_count > max_count do
    %{paginator | total_count: max_count}
  end

  defp max_count_constraint(paginator), do: paginator

  # TODO: refactor
  # Not of fan of how this is checking if group_by or multi source from.
  # Also the repeated use of total_count as a name bothers me.

  defp total_count(query = %{group_bys: [_ | _]}), do: total_row_count(query)
  defp total_count(query = %{from: %{source: {_, nil}}}), do: total_row_count(query)

  defp total_count(query) do
    primary_key = get_primary_key(query)

    query
    |> exclude(:select)
    |> select([i], count(field(i, ^primary_key), :distinct))
  end

  defp total_row_count(query) do
    query
    |> subquery()
    |> select(count("*"))
  end

  defp get_primary_key(query) do
    new_query =
      case is_map(query) do
        true -> query.from.source |> elem(1)
        _ -> query
      end

    new_query
    |> apply(:__schema__, [:primary_key])
    |> hd
  end

  defp page_constraint(%{page: page, max_page: max_page} = paginator) when page > max_page do
    %{paginator | page: max_page}
  end

  defp page_constraint(paginator), do: paginator

  # TODO: refactor
  defp process_query(%{page: page, per_page: per_page} = paginator, query) do
    offset = (page - 1) * per_page

    {
      paginator,
      query
      |> limit(^per_page)
      |> offset(^offset)
    }
  end

  defp return_query_results({%{lazy: false} = paginator, query}, repo) do
    {repo.all(query), paginator}
  end

  defp return_query_results({%{lazy: true} = paginator, query}, repo) do
    {query, paginator}
  end

  # Utils ---

  defp drop_nil(%{} = map) do
    map
    |> Enum.filter(fn {_, v} -> v end)
    |> Enum.into(%{})
  end
end
