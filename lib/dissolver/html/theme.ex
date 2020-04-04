defmodule Dissolver.HTML.Theme do
  @callback generate_links(any, String.t()) ::
              {:safe, [binary | maybe_improper_list(any, binary | [])]}
end
