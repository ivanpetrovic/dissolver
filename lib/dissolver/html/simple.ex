defmodule Dissolver.HTML.Simple do
  @behaviour Dissolver.HTML.Theme
  use Phoenix.HTML

  @moduledoc """
  This is a simple nav theme
  """

  @impl Dissolver.HTML.Theme
  def generate_links(page_list, additional_class) do
    content_tag :nav, class: build_html_class(additional_class) do
      for {label, _page, url, current} <- page_list do
        link("#{label}", to: url, class: build_html_class(current))
      end
    end
  end

  defp build_html_class(true), do: "active"
  defp build_html_class(false), do: nil

  defp build_html_class(additional_class) do
    String.trim("pagination #{additional_class}")
  end
end
