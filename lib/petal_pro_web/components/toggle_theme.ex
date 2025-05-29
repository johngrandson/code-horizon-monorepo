defmodule PetalProWeb.ToggleTheme do
  @moduledoc false
  use Phoenix.Component
  use PetalComponents

  attr :theme, :atom, required: true

  def theme_toggle_button(assigns) do
    ~H"""
    <button
      phx-click="toggle_theme"
      class={[
        "fixed top-4 right-4 z-50 p-3 rounded-full border transition-all duration-300 shadow-lg hover:scale-110",
        if(@theme == :dark,
          do: "bg-white/90 border-gray-200 text-gray-900 hover:bg-white",
          else: "bg-gray-900/90 border-gray-700 text-white hover:bg-gray-900"
        )
      ]}
      title={if @theme == :dark, do: "Switch to Light Mode", else: "Switch to Dark Mode"}
    >
      <%= if @theme == :dark do %>
        <.icon name="hero-sun" class="w-6 h-6" />
      <% else %>
        <.icon name="hero-moon" class="w-6 h-6" />
      <% end %>
    </button>
    """
  end
end
