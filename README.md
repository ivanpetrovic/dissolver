---
permalink: /docs/index.html
---

# Dissolver
### NOTE: This is a wip repo. It's not currently in working order and has many bugs. 

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

![CI](https://github.com/MorphicPro/dissolver/workflows/CI/badge.svg) [![Coverage Status](https://coveralls.io/repos/github/MorphicPro/dissolver/badge.svg?branch=release_1)](https://coveralls.io/github/MorphicPro/dissolver?branch=release_1)

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
