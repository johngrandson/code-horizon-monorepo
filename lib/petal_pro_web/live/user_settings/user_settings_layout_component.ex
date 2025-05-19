defmodule PetalProWeb.UserSettingsLayoutComponent do
  @moduledoc """
  A layout for any user setting screen like "Change email", "Change password" etc
  """
  use PetalProWeb, :component
  use PetalComponents

  attr :current_user, :map
  attr :current_page, :atom
  slot :inner_block

  def settings_layout(assigns) do
    ~H"""
    <.layout current_page={@current_page} current_user={@current_user} type="sidebar">
      <.container max_width="xl" class="py-10">
        <.page_header title={gettext("Settings")} />

        <.sidebar_tabs_container current_page={@current_page} menu_items={menu_items(@current_user)}>
          {render_slot(@inner_block)}
        </.sidebar_tabs_container>
      </.container>
    </.layout>
    """
  end

  defp menu_items(current_user) do
    PetalProWeb.Menus.build_menu(
      [
        :edit_profile,
        :edit_email,
        :edit_password,
        :edit_notifications,
        :edit_totp,
        :org_invitations,
        :billing
      ],
      current_user
    )
  end
end
