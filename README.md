# Dissolver
## NOTE: This is a wip repo. It's not currently in working order and has many bugs. 

This project is a fork of https://github.com/elixirdrops/kerosene.   
I thought to take it over because it does not look as if its being activly developed
and I think there is a some more work before it's a release canidate.

My hope is to refactor the code and tests to better the over all code quality as well as offer some needed features. 

The two first new features will include:
* Lazy query - Instead of pagination calling Repo.all it will return an Ecto query. This is useful for subqueries where you will passying the query to something like a preload. 
* Custom themes - Now you can pass a module as the source of your theme. 

Issues I' like to address:
* Many of the functions are public for the sake of testing. I would like refactor all the test so that the modules only exposed required interfaces. 
* The way this lib queries for total counts is a bit odd since it's trying to account for groub_by and multi sourced froms. I'm going to see if we can't make this cleaner. 
* The over all namespace of functions are in need of help. I will be refactoring a considerable amount of the functions. 

Pagination for Ecto and Phoenix.


## Installation

The package is [available in Hex](https://hex.pm/packages/dissolver), the package can be installed as:

Add dissolver to your list of dependencies in `mix.exs`:
```elixir
def deps do
  [{:dissolver, "~> 0.9.0"}]
end
```

Add Dissolver to your `repo.ex`:
```elixir
defmodule MyApp.Repo do
  use Ecto.Repo, 
    otp_app: :testapp,
    adapter: Ecto.Adapters.Postgres
  use Dissolver, per_page: 2
end
```

## Usage
Start paginating your queries 
```elixir
def index(conn, params) do
  {products, dissolver} =
  Product
  |> Product.with_lowest_price
  |> Repo.paginate(params)

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

Dissolver provides a [list ](https://hexdocs.pm/dissolver/Dissolver.HTML.html#__using__/1) of themes for pagination. By default it uses a simple theme. To set the theme provide a module that implements the , add to config/config.exs:
```elixir
config :dissolver,
	theme: :foundation
```

If you need reduced number of links in pagination, you can use `simple mode` option, to display only Prev/Next links:
```elixir
config :dissolver,
	mode:  :simple
```

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
