defmodule PetalPro.MarkdownRenderer do
  @moduledoc """
  Renders markdown as HTML. HtmlSanitizeEx is used to stop XSS attacks in user generated content.
  """
  require Phoenix.LiveViewTest

  def to_html(markdown \\ "", opts \\ earmark_options())

  def to_html(markdown, opts) when is_binary(markdown) do
    markdown
    |> Earmark.as_html!(opts)
    |> HtmlSanitizeEx.html5()
  end

  def to_html(_markdown, _opts), do: ""

  defp earmark_options do
    %Earmark.Options{
      code_class_prefix: "language-"
    }
  end
end
