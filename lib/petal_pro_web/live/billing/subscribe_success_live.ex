defmodule PetalProWeb.SubscribeSuccessLive do
  @moduledoc false
  use PetalProWeb, :live_view

  import PetalProWeb.OrgLayoutComponent

  alias PetalPro.Billing.Subscriptions

  @impl true
  def mount(%{"customer_id" => customer_id}, _session, socket) do
    socket =
      socket
      |> assign(:page_title, gettext("Subscribed"))
      |> assign(:subscription_status, :loading)
      |> assign(:subscription, nil)
      |> assign(:customer_id, customer_id)
      |> assign(:source, socket.assigns.live_action)
      |> assign(:pings, 0)
      |> assign_subscription()

    {:ok, socket}
  end

  @impl true
  def handle_info(:check_subscription, socket) do
    {:noreply, assign_subscription(socket)}
  end

  defp assign_subscription(%{assigns: %{pings: 5}} = socket) do
    assign(socket, :subscription_status, :failed)
  end

  defp assign_subscription(socket) do
    subscription =
      Subscriptions.get_subscription_by(%{
        status: "active",
        billing_customer_id: socket.assigns.customer_id
      }) ||
        Subscriptions.get_subscription_by(%{
          status: "trialing",
          billing_customer_id: socket.assigns.customer_id
        })

    case subscription do
      nil ->
        schedule_membership_check()
        assign(socket, :pings, socket.assigns.pings + 1)

      subscription ->
        socket
        |> assign(:subscription, subscription)
        |> assign(:subscription_status, :success)
    end
  end

  defp schedule_membership_check do
    Process.send_after(self(), :check_subscription, 1500)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <%= case @source do %>
      <% :user -> %>
        <.layout current_page={:subscribe} current_user={@current_user}>
          <.subscription_status
            subscription_status={@subscription_status}
            subscription={@subscription}
          />
        </.layout>
      <% :org -> %>
        <.org_layout
          current_page={:org_subscribe}
          current_user={@current_user}
          current_org={@current_org}
          current_membership={@current_membership}
          socket={@socket}
        >
          <.subscription_status
            subscription_status={@subscription_status}
            subscription={@subscription}
          />
        </.org_layout>
    <% end %>
    """
  end

  def subscription_status(assigns) do
    ~H"""
    <.container class="my-12" id="subscription-status">
      <.spinner show={@subscription_status == :loading} size="lg" />
      <.h2 :if={@subscription_status == :failed}>
        {gettext("Subscription failed. Please contact support.")}
      </.h2>
      <.h2 :if={@subscription} class="text-center">{gettext("Thank you for joining us!")}</.h2>
    </.container>
    """
  end
end
