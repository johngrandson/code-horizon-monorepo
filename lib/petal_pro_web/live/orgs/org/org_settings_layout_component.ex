defmodule PetalProWeb.OrgSettingsLayoutComponent do
  @moduledoc """
  A layout for any user setting screen like "Change email", "Change password" etc
  """
  use PetalProWeb, :component
  use PetalComponents

  import PetalProWeb.OrgLayoutComponent

  alias PetalPro.Billing.Customers

  attr :current_user, :map, required: true
  attr :current_org, :map, required: true
  attr :current_membership, :map, required: true
  attr :socket, :map, required: true
  attr :current_page, :atom
  slot :inner_block

  def org_settings_layout(assigns) do
    ~H"""
    <.org_layout
      current_page={:org_settings}
      current_user={@current_user}
      current_org={@current_org}
      current_membership={@current_membership}
      socket={@socket}
    >
      <.container max_width="xl" class="py-5">
        <.page_header title={gettext("%{org_name} settings", org_name: @current_org.name)} />

        <.sidebar_tabs_container current_page={@current_page} menu_items={menu_items(@current_org)}>
          {render_slot(@inner_block)}
        </.sidebar_tabs_container>
      </.container>
    </.org_layout>
    """
  end

  defp menu_items(current_org) do
    Enum.filter(
      [
        %{
          name: :edit_org,
          path: ~p"/app/org/#{current_org.slug}/edit",
          label: gettext("Edit"),
          icon: "hero-pencil-square"
        },
        %{name: :org_team, path: ~p"/app/org/#{current_org.slug}/team", label: gettext("Team"), icon: "hero-users"},
        org_billing_menu_item(current_org)
      ],
      & &1
    )
  end

  defp org_billing_menu_item(current_org) do
    if Customers.entity() == :org do
      %{
        name: :org_billing,
        label: gettext("Billing"),
        path: ~p"/app/org/#{current_org.slug}/billing",
        icon: "hero-credit-card"
      }
    end
  end
end
