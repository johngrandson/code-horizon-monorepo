defmodule PetalProWeb.Components.ThemeToggle do
  @moduledoc """
  Theme toggle component for switching between light and dark modes.
  """
  use PetalProWeb, :html

  attr :theme, :atom, required: true
  attr :on_toggle, JS, required: true

  def theme_toggle(assigns) do
    ~H"""
    <button
      phx-click={@on_toggle}
      class={[
        "p-2 rounded-lg border transition-all duration-300 hover:scale-105",
        if(@theme == :light,
          do: "bg-gray-100 border-gray-200 text-gray-800 hover:bg-gray-200",
          else: "bg-gray-800 border-gray-700 text-white hover:bg-gray-700"
        )
      ]}
      title="Toggle theme"
    >
      <%= if @theme == :light do %>
        <.icon name="hero-moon" class="w-5 h-5" />
      <% else %>
        <.icon name="hero-sun" class="w-5 h-5" />
      <% end %>
    </button>
    """
  end
end
