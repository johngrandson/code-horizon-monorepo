defmodule PetalProWeb.AdminOrgLive.Show do
  @moduledoc false
  use PetalProWeb, :live_view

  import PetalProWeb.AdminLayoutComponent

  alias PetalPro.Billing.Customers
  alias PetalPro.Orgs

  @billing_provider Application.compile_env(:petal_pro, :billing_provider)

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"slug" => slug}, _, socket) do
    org =
      slug
      |> Orgs.get_org!()
      |> Orgs.preload_org_memberships()

    {:noreply,
     socket
     |> assign(:billing_provider, @billing_provider)
     |> assign(:page_title, page_title(socket.assigns.live_action, org))
     |> assign(:org, org)}
  end

  @impl true
  def handle_event("close_modal", _, socket) do
    {:noreply, push_patch(socket, to: ~p"/admin/orgs/#{socket.assigns.org}")}
  end

  @impl true
  def handle_event("sync_org_billing", _, socket) do
    with %Customers.Customer{} = customer <- Customers.get_customer_by_source(:org, socket.assigns.org.id),
         :ok <- @billing_provider.sync_subscription(customer) do
      socket =
        socket
        |> put_flash(:info, gettext("%{model} billing synced", model: gettext("Organization")))
        |> push_patch(to: ~p"/admin/orgs/#{socket.assigns.org}")

      {:noreply, socket}
    else
      _ ->
        {:noreply, put_flash(socket, :info, gettext("No %{model} billing found", model: gettext("Organization")))}
    end
  end

  @impl true
  def handle_event("membership_delete", %{"id" => id}, socket) do
    membership = Orgs.get_membership!(id)
    {:ok, _} = Orgs.delete_membership(membership)

    {:noreply,
     socket
     |> put_flash(:info, gettext("%{model} successfully deleted", model: gettext("Membership")))
     |> assign(:org, socket.assigns.org.slug |> Orgs.get_org!() |> Orgs.preload_org_memberships())}
  end

  @impl true
  def handle_event("membership_edit", %{"id" => id}, socket) do
    {:noreply,
     socket
     |> assign(:live_action, :edit_membership)
     |> assign(:membership, Orgs.get_membership!(id))}
  end

  @impl true
  def handle_event("membership_add", _, socket) do
    {:noreply,
     socket
     |> assign(:live_action, :new_membership)
     |> assign(:membership, %Orgs.Membership{})}
  end

  defp page_title(:show, org), do: gettext("%{model} - %{org}", model: gettext("Organization"), org: org.name)
  defp page_title(:edit, _org), do: gettext("Edit %{model}", model: gettext("Organization"))

  defp membership_title(:new_membership), do: gettext("Add %{model}", model: gettext("User"))
  defp membership_title(:edit_membership), do: gettext("Edit %{model}", model: gettext("User"))
end
