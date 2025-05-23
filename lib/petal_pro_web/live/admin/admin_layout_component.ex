defmodule PetalProWeb.AdminLayoutComponent do
  @moduledoc false
  use PetalProWeb, :component
  use PetalComponents

  alias PetalProWeb.AlpineComponents
  alias PetalProWeb.Menus

  attr :current_user, :map, required: true
  attr :current_page, :atom
  slot(:inner_block)

  def admin_layout(assigns) do
    ~H"""
    <.layout
      current_page={@current_page}
      current_user={@current_user}
      type="sidebar"
      sidebar_title="Admin"
      main_menu_items={menu_items(@current_user)}
    >
      <.container max_width="xl" class="my-4">
        <AlpineComponents.js_setup />

        {render_slot(@inner_block)}
      </.container>
    </.layout>
    """
  end

  def menu_items(current_user) do
    [
      %{
        title: "Admin",
        menu_items: [
          Menus.get_link(:admin_dashboard, current_user),
          Menus.get_link(:admin_users, current_user),
          Menus.get_link(:admin_orgs, current_user),
          Menus.get_link(:admin_posts, current_user),
          Menus.get_link(:admin_subscriptions, current_user),
          Menus.get_link(:admin_logs, current_user),
          Menus.get_link(:admin_settings, current_user)
        ]
      },
      %{
        title: "Server",
        menu_items: [
          %{
            name: :server,
            label: gettext("Live dashboard"),
            path: ~p"/admin/server",
            icon: "hero-chart-bar-square"
          },
          %{
            name: :oban_web,
            label: gettext("Oban Web"),
            path: ~p"/admin/oban",
            icon: "hero-server-stack"
          },
          Menus.get_link(:admin_interactive, current_user)
        ]
      }
    ]
  end
end
