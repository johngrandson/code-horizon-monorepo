defmodule PetalProWeb.DataTable.Cell do
  @moduledoc false
  use Phoenix.Component

  import PetalComponents.Button

  def render(%{column: %{renderer: :checkbox}} = assigns) do
    ~H"""
    <%= if get_value(assigns.item, assigns.column) do %>
      <input
        type="checkbox"
        checked
        disabled
        class="shrink-0 border-stone-300 rounded-sm text-green-600 focus:ring-green-600 checked:border-green-600 disabled:opacity-50 disabled:pointer-events-none dark:bg-neutral-800 dark:border-neutral-600 dark:checked:bg-green-500 dark:checked:border-green-500 dark:focus:ring-offset-neutral-800"
      />
    <% else %>
      <input
        type="checkbox"
        disabled
        class="shrink-0 border-stone-300 rounded-sm text-stone-600 focus:ring-stone-600 disabled:opacity-50 disabled:pointer-events-none dark:bg-neutral-800 dark:border-neutral-600 dark:focus:ring-offset-neutral-800"
      />
    <% end %>
    """
  end

  def render(%{column: %{renderer: :date}} = assigns) do
    ~H"""
    <span class="text-sm text-stone-600 dark:text-neutral-400">
      {Calendar.strftime(
        get_value(assigns.item, assigns.column),
        assigns.column[:date_format] || "%Y-%m-%d"
      )}
    </span>
    """
  end

  def render(%{column: %{renderer: :datetime}} = assigns) do
    ~H"""
    <span class="text-sm text-stone-600 dark:text-neutral-400">
      {Calendar.strftime(
        get_value(assigns.item, assigns.column),
        assigns.column[:date_format] || "%I:%M%p %Y-%m-%d"
      )}
    </span>
    """
  end

  def render(%{column: %{renderer: :money}} = assigns) do
    ~H"""
    <span class="text-sm font-medium text-stone-800 dark:text-neutral-200">
      {parse_money(get_value(assigns.item, assigns.column), assigns.column[:currency] || "USD")
      |> Money.to_string()}
    </span>
    """
  end

  def render(%{column: %{renderer: :action_buttons}} = assigns) do
    ~H"""
    <div class="flex items-center gap-2">
      <%= for button <- assigns.column.buttons.(assigns.item) do %>
        <.button {button} />
      <% end %>
    </div>
    """
  end

  # New renderer for status/badge style
  def render(%{column: %{renderer: :badge}} = assigns) do
    value = get_value(assigns.item, assigns.column)
    assigns = assign(assigns, :value, value)
    assigns = assign(assigns, :badge_color, get_badge_color(value, assigns.column[:badge_colors]))

    ~H"""
    <span class={"py-1.5 px-2 inline-flex items-center text-xs font-medium rounded-full #{@badge_color}"}>
      <%= if @column[:badge_icon] do %>
        {@column.badge_icon.(@value)}
      <% end %>
      {@value}
    </span>
    """
  end

  # New renderer for code/identifier style
  def render(%{column: %{renderer: :code}} = assigns) do
    ~H"""
    <span class="p-2 bg-stone-100 text-stone-800 text-xs font-mono rounded-md cursor-pointer dark:bg-neutral-700 dark:text-neutral-200">
      <span class="uppercase">{get_value(assigns.item, assigns.column)}</span>
    </span>
    """
  end

  # Plain text (default)
  def render(assigns) do
    # Determine text style based on column attributes
    text_class =
      cond do
        assigns.column[:primary] -> "text-sm font-medium text-stone-800 dark:text-neutral-200"
        assigns.column[:secondary] -> "text-sm text-stone-600 dark:text-neutral-400"
        true -> "text-sm text-stone-800 dark:text-neutral-200"
      end

    assigns = assign(assigns, :text_class, text_class)

    ~H"""
    <span class={@text_class}>
      {get_value(assigns.item, assigns.column)}
    </span>
    """
  end

  # Helper function for badge colors
  defp get_badge_color(value, badge_colors) when is_map(badge_colors) do
    Map.get(badge_colors, value, "bg-stone-100 text-stone-800 dark:bg-neutral-700 dark:text-neutral-200")
  end

  defp get_badge_color(_value, _badge_colors) do
    "bg-stone-100 text-stone-800 dark:bg-neutral-700 dark:text-neutral-200"
  end

  defp parse_money(amount, currency) when is_integer(amount) do
    Money.new(amount * 100, currency)
  end

  defp parse_money(amount, currency) when is_float(amount) do
    amount |> Decimal.from_float() |> Money.parse!(currency)
  end

  defp parse_money(amount, currency) when is_binary(amount) do
    Money.parse!(amount, currency)
  end

  defp get_value(item, column) do
    cond do
      is_function(column[:renderer]) -> column.renderer.(item)
      !!column[:field] -> Map.get(item, column.field)
      true -> nil
    end
  end
end
