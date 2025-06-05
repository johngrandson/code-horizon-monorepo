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
      main_menu_items={build_combined_menu(@current_membership, @current_org)}
      type="sidebar"
      sidebar_title={@current_org.name}
    >
      {render_slot(@inner_block)}
    </.layout>
    """
  end

  defp build_combined_menu(membership, org) do
    main_menu = build_menu(membership, org)
    app_modules_menu = build_app_modules_menu(org)

    combined =
      case app_modules_menu do
        [] ->
          main_menu

        modules ->
          main_menu ++ modules
      end

    combined
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

  defp build_app_modules_menu(org) do
    case has_active_modules?(org) do
      %{virtual_queues: true} ->
        [get_link(:org_virtual_queues, org)]

      %{blog_maker: true} ->
        [get_link(:org_blog_maker, org)]

      _ ->
        []
    end
  end

  defp has_active_modules?(org) do
    case org.module_subscriptions do
      %Ecto.Association.NotLoaded{} ->
        %{}

      subscriptions when is_list(subscriptions) ->
        subscriptions
        |> Enum.filter(&subscription_active?/1)
        |> Enum.reduce(%{}, fn subscription, acc ->
          Map.put(acc, String.to_atom(subscription.module_code), true)
        end)

      _ ->
        %{}
    end
  end

  defp subscription_active?(%{active: true, expires_at: nil}), do: true

  defp subscription_active?(%{active: true, expires_at: expires_at}) do
    DateTime.before?(DateTime.utc_now(), expires_at)
  end

  defp subscription_active?(_), do: false

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

  defp get_link(:org_virtual_queues, org) do
    %{
      name: :org_virtual_queues,
      path: ~p"/app/org/#{org.slug}/virtual-queues",
      label: gettext("Virtual Queues"),
      icon: "hero-ticket"
    }
  end

  defp get_link(:org_blog_maker, org) do
    %{
      name: :org_blog_maker,
      path: ~p"/app/org/#{org.slug}/blog-maker",
      label: gettext("Blog Maker"),
      icon: "hero-chat-bubble-bottom-center-text"
    }
  end
end
