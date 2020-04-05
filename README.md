# Dissolver
## NOTE: This is a wip repo. It's not currently in working order and has many bugs. 

This project is a fork of https://github.com/elixirdrops/kerosene.   
I thought to take it over because it does not look as if its being activly developed
and I think there is some more work needed before it's a release canidate.

My hope is to refactor the code and tests to better the over all code quality as well as offer some needed features. 

The two first new features will include:
* Lazy query - Instead of pagination calling Repo.all it will return an Ecto query. This is useful for subqueries where you will passying the query to something like a preload. 
* Custom themes - Now you can pass a module as the source of your theme. 

Issues I' like to address:
* Many of the functions are public for the sake of testing. I would like refactor all the test so that the modules only exposed required interfaces. 
* The way this lib queries for total counts is a bit odd since it's trying to account for groub_by and multi sourced froms. I'm going to see if we can't make this cleaner. 
* The over all namespace of functions are in need of help. I will be refactoring a considerable amount of the functions. 

--- 

![CI](https://github.com/joshchernoff/dissolver/workflows/CI/badge.svg) [![Coverage Status](https://coveralls.io/repos/github/joshchernoff/dissolver/badge.svg?branch=release_1)](https://coveralls.io/github/joshchernoff/dissolver?branch=release_1)

Pagination for Ecto and Phoenix.


## Installation

The package is [available in Hex](https://hex.pm/packages/dissolver), the package can be installed as:

Add dissolver to your list of dependencies in `mix.exs`:
```elixir
def deps do
  [{:dissolver, "~> 0.9.0"}]
end
```

Add Dissolver's config to your `config/config.ex`:
```elixir
  ...
  config :dissolver,
    repo: MyApp.Repo, 
    theme: Dissolver.HTML.Bootstap, 
    per_page: 2

  import_config "#{Mix.env()}.exs"
```
Note: See Config options for more settings.

## Usage
Start paginating your queries 
```elixir
def index(conn, params) do
  {products, dissolver} =
  Product
  |> Product.with_lowest_price
  |> Dissolver.paginate(params)

  render(conn, "index.html", products: products, dissolver: dissolver)
end
```

Add view helpers to your view 
```elixir
defmodule MyApp.ProductView do
  use MyApp.Web, :view
  import Dissolver.HTML
end
```

Generate the links using the view helpers
```elixir
<%= paginate @conn, @dissolver %>
```

If you need reduced number of links in pagination, you can use the `Dissolver.HTML.Simple` theme, to display only Prev/Next links:
```elixir
config :dissolver,
	theme:  Dissolver.HTML.Simple
```
Note this is also the default theme if no other theme option is provided. 

Building apis or SPA's, no problem Dissolver has support for Json.

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


You can also send in options to paginate helper look at the docs for more details.

## Contributing
	
Please do send pull requests and bug reports, positive feedback is always welcome.


## Acknowledgement

I would like to Thank

* Matt (@mgwidmann)
* Drew Olson (@drewolson)
* Akira Matsuda (@amatsuda)

## License

Please take a look at LICENSE.md
