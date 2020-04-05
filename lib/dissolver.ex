defmodule Dissolver do
  import Ecto.Query

  alias Dissolver.Paginator

  @default [
    per_page: 10,
    max_page: 100,
    page: 1,
    lazy: false
  ]

  @moduledoc """
  Pagination for Ecto and Phoenix.

  Configuration's order of specificity:
  Dissolver has some sensible defaults of which can be overriden by any of the following.
  Config file are treated like globals will override defaults and can be overriden by the following.
  Request Params will override globals.
  Function arguments will override request params.
  """

  @spec paginate(Ecto.Query.t(), map(), nil | keyword()) :: {list(), Paginator.t()}
  def paginate(query, params, opts \\ []) do
    # TODO:
    # Parse options
    # Get totals
    # Build a Query
    # Run or return query
    # Build a Paginator

    # Parse options
    # options = build_options(opts, params)

    # Get totals
    # {:ok, %{total_count: total_count, total_pages: total_pages}} = get_totals()

    # Build query
    # To build a query we need:
    # 1: the current query
    # 2: a limit
    # 3: a offset unless there is no offset
    # query
    # |> Query.limit(params, opts)
    # |> Query.offset()

    options = build_options(opts, params)

    repo = Application.fetch_env!(:dissolver, :repo)

    total_count = get_total_count(options[:total_count], repo, query)
    total_pages = get_total_pages(total_count, options[:per_page])

    page = get_page(options, total_pages)
    offset = get_offset(total_count, page, options[:per_page])

    {
      get_items(repo, query, options[:per_page], offset, options[:lazy]),
      %Paginator{
        per_page: options[:per_page],
        page: page,
        total_pages: total_pages,
        total_count: total_count,
        max_page: options[:max_page],
        params: params
      }
    }
  end

  # defp build_query(query, nil, _): do: query
  # defp build_query(query, limit, offset) do

  defp get_items(_repo, query, nil, _, true), do: query

  defp get_items(_repo, query, limit, offset, true) do
    query
    |> limit(^limit)
    |> offset(^offset)
  end

  defp get_items(repo, query, nil, _, false), do: repo.all(query)

  defp get_items(repo, query, limit, offset, false) do
    query
    |> limit(^limit)
    |> offset(^offset)
    |> repo.all
  end

  defp get_offset(total_pages, page, per_page) do
    page =
      case page > total_pages do
        true -> total_pages
        _ -> page
      end

    case page > 0 do
      true -> (page - 1) * per_page
      _ -> 0
    end
  end

  # TODO: This needs a whole refactor.
  # Not of fan of how this is checking if group_by or multi source from.
  # Maybe this should be its own module?
  # Also the repeated use of total_count as a name bothers me.
  defp get_total_count(count, _repo, _query) when is_integer(count) and count >= 0, do: count

  defp get_total_count(_count, repo, query) do
    query
    |> exclude(:preload)
    |> exclude(:order_by)
    |> total_count()
    # |> (&from(q in &1, select: fragment("count(*)"))).()
    |> repo.one() || 0
  end

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

  defp get_total_pages(_, nil), do: 1

  defp get_total_pages(count, per_page) do
    Float.ceil(count / per_page) |> trunc()
  end

  defp build_options(opts, params) do
    Keyword.merge(opts,
      page: get_page(params),
      per_page: get_per_page(opts),
      params: params,
      max_page: get_max_page(opts),
      lazy: get_lazy(opts)
    )
  end

  defp get_per_page(opts) do
    case Keyword.get(opts, :per_page) do
      nil -> Application.get_env(:dissolver, :per_page, @default[:per_page])
      per_page -> per_page
    end
    |> to_integer()
  end

  # FIXME: I really don't understand this logic.
  # My assumption is that max page is the limit at which you want some one to travel too.
  # From this logic is would put you past the max page,
  # also I don't know why you would allow to come in from params?
  defp get_page(params, total_pages) do
    case params[:page] > params[:max_page] do
      true -> total_pages
      _ -> params[:page]
    end
  end

  defp get_page(params) do
    Map.get(params, "page", @default[:page]) |> to_integer()
  end

  defp get_max_page(opts) do
    Keyword.get(opts, :max_page) ||
      Application.get_env(:dissolver, :max_page, @default[:max_page])
  end

  defp get_lazy(opts) do
    Keyword.get(opts, :lazy) ||
      Application.get_env(:dissolver, :lazy, @default[:lazy])
  end

  defp to_integer(i) when is_integer(i), do: abs(i)

  defp to_integer(i) when is_binary(i) do
    case Integer.parse(i) do
      {n, _} -> n
      _ -> 0
    end
  end

  defp to_integer(_), do: @default[:page]
end
