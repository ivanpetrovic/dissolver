defmodule Dissolver.HTML.Theme do
  @moduledoc """
  This is a behavior for implementing a custom Dissolver.HTML.Theme
  """
  @callback generate_links(any, String.t()) ::
              {:safe, [binary | maybe_improper_list(any, binary | [])]}
end
