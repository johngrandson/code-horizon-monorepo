defmodule PetalProWeb.SubscribeLive do
  @moduledoc false
  use PetalProWeb, :live_view

  import PetalProWeb.OrgLayoutComponent

  alias PetalPro.Billing.Customers
  alias PetalPro.Billing.Customers.Customer
  alias PetalPro.Billing.Plans
  alias PetalPro.Billing.Subscriptions
  alias PetalPro.Billing.Subscriptions.Subscription
  alias PetalPro.Logs
  alias PetalProWeb.BillingComponents
  alias PetalProWeb.BillingLive

  @billing_provider Application.compile_env(:petal_pro, :billing_provider)

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:page_title, gettext("Subscribe"))
      |> assign(:source, socket.assigns.live_action)
      |> assign(:products, Plans.products())

    socket =
      with %Customer{id: customer_id} = customer <- get_customer(socket.assigns.source, socket),
           %Subscription{} = subscription <-
             Subscriptions.get_active_subscription_by_customer_id(customer_id) do
        socket
        |> assign(:current_customer, customer)
        |> assign(:current_subscription, subscription)
      else
        nil -> assign(socket, :current_subscription, nil)
      end

    {:ok, socket}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.source_layout
      source={@source}
      current_user={@current_user}
      current_org={@current_org}
      current_membership={@current_membership}
      socket={@socket}
    >
      <.container class="my-12">
        <.h2 class="text-center mb-8">{gettext("Choose a plan")}</.h2>

        <BillingComponents.pricing_panels_container panels={length(@products)} interval_selector>
          <%= for product <- @products do %>
            <BillingComponents.pricing_panel
              id={"pricing-product-#{product.id}"}
              label={product.name}
              description={product.description}
              features={product.features}
              most_popular={Map.get(product, :most_popular)}
            >
              <%= for plan <- product.plans do %>
                <BillingComponents.item_price
                  id={"pricing-plan-#{plan.id}"}
                  interval={plan.interval}
                  amount={plan.amount}
                  button_props={button_props(plan, @current_subscription)}
                  button_label={subscribe_text(plan, @current_subscription)}
                  is_current_plan={current_plan?(plan, @current_subscription)}
                  billing_path={BillingLive.billing_path(@source, assigns)}
                />
              <% end %>
            </BillingComponents.pricing_panel>
          <% end %>
        </BillingComponents.pricing_panels_container>
      </.container>
    </.source_layout>
    """
  end

  defp current_plan?(plan, %Subscription{} = subscription) do
    plan.id == subscription.plan_id
  end

  defp current_plan?(_plan, _subscription), do: false

  defp subscribe_text(plan, subscription)
  defp subscribe_text(_plan, nil), do: gettext("Subscribe")
  defp subscribe_text(plan, subscription) when plan.id == subscription.plan_id, do: gettext("Current Plan - Cancel")
  defp subscribe_text(_plan, _subscription), do: gettext("Switch")

  defp button_props(plan, subscription)

  defp button_props(plan, nil) do
    %{"phx-click" => "checkout", "phx-value-plan" => plan.id}
  end

  defp button_props(plan, subscription) when plan.id == subscription.plan_id do
    %{"disabled" => true}
  end

  defp button_props(plan, _subscription) do
    %{"phx-click" => "switch_plan", "phx-value-plan" => plan.id}
  end

  attr :source, :atom, default: :user
  attr :current_user, :map, default: nil
  attr :current_org, :map, default: nil
  attr :current_membership, :map, default: nil
  attr :socket, :map, default: nil
  slot :inner_block, required: true

  defp source_layout(assigns) do
    ~H"""
    <%= case @source do %>
      <% :user -> %>
        <.layout current_page={:subscribe} current_user={@current_user}>
          {render_slot(@inner_block)}
        </.layout>
      <% :org -> %>
        <.org_layout
          current_page={:org_subscribe}
          current_user={@current_user}
          current_org={@current_org}
          current_membership={@current_membership}
          socket={@socket}
        >
          {render_slot(@inner_block)}
        </.org_layout>
    <% end %>
    """
  end

  @impl true
  def handle_event("checkout", %{"plan" => plan_id}, socket) do
    source = socket.assigns.source
    checkout_url = checkout_url(socket, source, plan_id)

    Logs.log("billing.click_subscribe_button", %{
      user: socket.assigns.current_user,
      metadata: %{
        plan_id: plan_id,
        org_id: current_org_id(socket)
      }
    })

    {:noreply, redirect(socket, to: checkout_url)}
  end

  def handle_event(
        "switch_plan",
        %{"plan" => plan_id},
        %{assigns: %{current_customer: customer, current_subscription: subscription}} = socket
      ) do
    plan = Plans.get_plan_by_id!(plan_id)

    case @billing_provider.change_plan(customer, subscription, plan) do
      {:ok, session} ->
        url = @billing_provider.checkout_url(session)
        {:noreply, redirect(socket, external: url)}

      {:error, reason} ->
        {
          :noreply,
          put_flash(socket, :error, gettext("Something went wrong with our payment portal. ") <> inspect(reason))
        }
    end
  end

  defp checkout_url(_socket, :user, plan_id), do: ~p"/app/checkout/#{plan_id}"

  defp checkout_url(socket, :org, plan_id) do
    org_slug = current_org_slug(socket)

    ~p"/app/org/#{org_slug}/checkout/#{plan_id}"
  end

  defp current_org_id(socket) do
    case socket.assigns.current_org do
      nil -> nil
      org -> org.id
    end
  end

  defp current_org_slug(socket) do
    case socket.assigns.current_org do
      nil -> nil
      org -> org.slug
    end
  end

  defp get_customer(:org, socket) do
    Customers.get_customer_by_source(:org, socket.assigns.current_org.id)
  end

  defp get_customer(:user, socket) do
    Customers.get_customer_by_source(:user, socket.assigns.current_user.id)
  end
end
