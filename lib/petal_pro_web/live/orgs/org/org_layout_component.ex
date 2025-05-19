defmodule PetalProWeb.OrgLayoutComponent do
  @moduledoc """
  A layout for any page scoped to an org. eg "Org dashboard", "Org settings", etc.
  """
  use PetalProWeb, :component

  alias PetalPro.Billing.Customers

  attr :socket, :map, required: true
  attr :current_user, :map, required: true
  attr :current_org, :map, required: true
  attr :current_membership, :map, required: true
  attr :current_page, :atom
  slot(:inner_block)

  def org_layout(assigns) do
    ~H"""
    <.layout
      current_page={@current_page}
      current_user={@current_user}
      main_menu_items={build_menu(@current_membership, @current_org)}
      type="sidebar"
      sidebar_title={@current_org.name}
    >
      {render_slot(@inner_block)}
    </.layout>
    """
  end

  defp build_menu(membership, org) do
    case membership.role do
      :member ->
        [
          get_link(:org_dashboard, org)
        ]

      :admin ->
        Enum.filter(
          [
            get_link(:org_dashboard, org),
            get_link(:org_settings, org),
            get_link(:org_subscribe, org)
          ],
          & &1
        )
    end
  end

  defp get_link(:org_dashboard, org) do
    %{
      name: :org_dashboard,
      path: ~p"/app/org/#{org.slug}",
      label: gettext("Org Dashboard"),
      icon: "hero-building-office"
    }
  end

  defp get_link(:org_settings, org) do
    %{
      name: :org_settings,
      path: ~p"/app/org/#{org.slug}/edit",
      label: gettext("Org Settings"),
      icon: "hero-cog"
    }
  end

  defp get_link(:org_subscribe, org) do
    if Customers.entity() == :org do
      %{
        name: :org_subscribe,
        path: ~p"/app/org/#{org.slug}/subscribe",
        label: gettext("Subscribe"),
        icon: "hero-shopping-bag"
      }
    end
  end
end
