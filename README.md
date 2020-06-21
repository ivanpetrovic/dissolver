# Dissolver
### NOTE: This is a wip repo. So be warned there maybe be bugs. 

This project is a fork of https://github.com/elixirdrops/kerosene.   
I thought to take it over because it does not look as if its being activly developed
and I wanted more features.

My hope is to refactor the code and tests to better the over all code quality as well as offer some needed features. 

The two main new features are:
* Lazy query - Instead of pagination calling Repo.all it will return an Ecto query. This is useful for subqueries where you will passying the query to something like a preload.
* Custom themes - Now you can pass a module as the source of your theme. 

Pending Issues I'd like to address:
* Many of the functions are public for the sake of testing. I would like refactor all the test so that the modules only exposed required interfaces. 
* The way this lib queries for total counts is a bit odd since it's trying to account for groub_by and multi sourced froms. I'm going to see if we can't make this cleaner. 
* The over all namespace of functions are in need of help. I will be refactoring a considerable amount of the functions. 

--- 

![CI](https://github.com/MorphicPro/dissolver/workflows/CI/badge.svg) [![Coverage Status](https://coveralls.io/repos/github/MorphicPro/dissolver/badge.svg?branch=master)](https://coveralls.io/github/MorphicPro/dissolver?branch=master)

Pagination for Ecto and Phoenix.

Dissolver was forked of the fine work [kerosene](https://github.com/elixirdrops/kerosene)

## Installation
add Dissolver to your mix.exs dependencies:
```elixir
def deps do
  [
    {:dissolver, github: 'MorphicPro/dissolver'}
  ]
end
```

Next provide Dissolver your Repo module via the config.
Add the following to your config:
```elixir
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
```elixir
def index(conn, params) do
  {products, paginator} =
  Product
  |> Product.with_lowest_price
  |> Dissolver.paginate(params)

  render(conn, "index.html", products: products, paginator: paginator)
end
```

Add the view helper to your view
```elixir
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

* `:per_page` (default: 20) - The global per page setting
* `:max_page` - The limit of pages allow to navigate regardless of total pages found
    This option is ignored if not provided and defaults to total pages found in the query.
* `:lazy` (default: false) - This option if enabled will result in all `Dissolver.paginate/3` calls
    return an Ecto.Query rather than call Repo.all. This is useful for when you need to paginate
    on an association via a preload. TODO: provide example.
    
## JSON API Support.

```elixir
defmodule MyApp.ProductView do
  use MyApp.Web, :view
  import Dissolver.JSON

  def render("index.json", %{products: products, dissolver: dissolver, conn: conn}) do
    %{data: render_many(products, MyApp.ProductView, "product.json"),
      pagination: paginate(conn, dissolver)}
  end

  def render("product.json", %{product: product}) do
    %{id: product.id,
      name: product.name,
      description: product.description,
      price: product.price}
  end
end
```

## Lazy Example. 

Say you have a tag that has many posts and you want to paginate the post as they relate to a given tag. 

Heres an example of using the lazy option so that Dissolver.paginate returns a query rather than a result. 

```elixir
def get_post_for_tag!(tag_name, params \\ %{}) do
    total_count =
      from(t in "tags",
        join: pt in "post_tags",
        on: pt.tag_id == t.id,
        where: t.name == ^tag_name,
        select: count()
      )
      |> Repo.one()

    {posts_query, paginator} =
      from(p in Post, order_by: [desc: :inserted_at], preload: [:tags])
      |> Dissolver.paginate(params, total_count: total_count, lazy: true)

    tag =
      from(t in Tag, where: t.name == ^tag_name, preload: [posts: ^posts_query])
      |> Repo.one!()

    {tag, paginator}
  end
```

You will notice that in this case I also have to supply total_count since Dissolver.paginate does not currently have a way to scope total_count of a given tag since they query is applied after Dissolver.paginate was called. So for this use case we just supply the total count up front. 

For my controller it looks just like most.

```elixir
def show_post(conn, %{"tag" => tag} = params) do
  {tag, paginator} = Blog.get_post_for_tag!(tag, params)
  render(conn, "show_posts.html", tag: tag, paginator: paginator)
end
```


You can also send in options to paginate helper look at the docs for more details.

## Contributing
If you can start by writing an issue ticket. 
Then if you like feel free to fork and submit a PR for review. 

## Acknowledgement

I would like to Thank

* Matt (@mgwidmann)
* Drew Olson (@drewolson)
* Akira Matsuda (@amatsuda)

## License

Please take a look at LICENSE.md
