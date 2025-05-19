defmodule PetalProWeb.BillingLive do
  @moduledoc false
  use PetalProWeb, :live_view

  import PetalProWeb.OrgSettingsLayoutComponent
  import PetalProWeb.UserSettingsLayoutComponent

  alias PetalPro.Billing.Subscriptions
  alias PetalPro.Billing.Subscriptions.Subscription

  @billing_provider Application.compile_env(:petal_pro, :billing_provider)

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:source, socket.assigns.live_action)
      |> assign(:billing_provider, @billing_provider)

    {:ok, socket}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, maybe_load_provider_data(socket)}
  end

  @impl true
  def handle_event("cancel_subscription", _attrs, %{assigns: assigns} = socket) do
    provider_sub = assigns.provider_subscription_async.result
    subscription = assigns.subscription

    with {:ok, _provider_subscription} <- @billing_provider.cancel_subscription(provider_sub.id),
         %Subscription{} = subscription <- Subscriptions.get_subscription!(subscription.id),
         {:ok, _suscription} <- Subscriptions.cancel_subscription(subscription) do
      Subscriptions.billing_lifecycle_action(
        "billing.cancel_subscription",
        assigns.current_user,
        assigns.current_org,
        %{
          subscription: subscription,
          customer: assigns.customer
        }
      )

      {:noreply, push_navigate(socket, to: billing_path(assigns.source, assigns))}
    else
      {:error, _reason} ->
        {
          :noreply,
          socket
          |> put_flash(:error, gettext("Something went wrong."))
          |> maybe_load_provider_data()
        }
    end
  end

  defp maybe_load_provider_data(socket) do
    subscription = socket.assigns[:subscription]

    assign_async(socket, [:provider_subscription_async, :provider_product_async], fn ->
      case subscription do
        nil ->
          {:ok, %{provider_subscription_async: nil, provider_product_async: nil}}

        subscription ->
          {:ok, provider_subscription} =
            @billing_provider.retrieve_subscription(subscription.provider_subscription_id)

          {:ok, provider_product} =
            provider_subscription
            |> @billing_provider.get_subscription_product()
            |> @billing_provider.retrieve_product()

          {:ok, %{provider_subscription_async: provider_subscription, provider_product_async: provider_product}}
      end
    end)
  end

  def billing_path(:user, _assigns), do: ~p"/app/billing"
  def billing_path(:org, assigns), do: ~p"/app/org/#{assigns.current_org.slug}/billing"

  defp subscribe_path(:user, _assigns), do: ~p"/app/subscribe"
  defp subscribe_path(:org, assigns), do: ~p"/app/org/#{assigns.current_org.slug}/subscribe"

  @impl true
  def render(assigns) do
    ~H"""
    <%= case @source do %>
      <% :user -> %>
        <.settings_layout current_page={:billing} current_user={@current_user}>
          <.h3>{gettext("Billing")}</.h3>
          <.active_subscription_info
            subscribe_path={subscribe_path(@source, assigns)}
            billing_provider={@billing_provider}
            provider_product_async={@provider_product_async}
            provider_subscription_async={@provider_subscription_async}
          />
        </.settings_layout>
      <% :org -> %>
        <.org_settings_layout
          current_page={:org_billing}
          current_user={@current_user}
          current_org={@current_org}
          current_membership={@current_membership}
          socket={@socket}
        >
          <.h3>{gettext("Billing")}</.h3>
          <.active_subscription_info
            subscribe_path={subscribe_path(@source, assigns)}
            billing_provider={@billing_provider}
            provider_product_async={@provider_product_async}
            provider_subscription_async={@provider_subscription_async}
          />
        </.org_settings_layout>
    <% end %>
    """
  end

  attr :billing_provider, :atom
  attr :provider_subscription_async, :map
  attr :provider_product_async, :map
  attr :subscribe_path, :string

  def active_subscription_info(assigns) do
    ~H"""
    <div :if={@provider_subscription_async.loading}><.spinner /></div>

    <div :if={@provider_subscription_async.failed}>
      {gettext("Something went wrong with our payment provider. Please contact support.")}
    </div>

    <div :if={
      _provider_subscription =
        @provider_subscription_async.ok? && !@provider_subscription_async.result
    }>
      {gettext("No active subscriptions.")}
      <div class="mt-3">
        <.button
          label={gettext("View plans")}
          link_type="live_redirect"
          to={@subscribe_path}
          color="light"
        />
      </div>
    </div>

    <div :if={
      provider_subscription = @provider_subscription_async.ok? && @provider_subscription_async.result
    }>
      <div>
        <span class="font-semibold">{gettext("Current plan:")}</span>
        {@provider_product_async.result.name}
        <span :if={@provider_subscription_async.result.status == "trialing"}>
          ({gettext("Trial")})
        </span>
      </div>
      <div>
        <span class="font-semibold">{gettext("Amount:")}</span>
        {provider_subscription |> @billing_provider.get_subscription_price() |> Util.format_money()}
        <span class="uppercase">{provider_subscription.currency}</span>
      </div>
      <div>
        <span class="font-semibold">{gettext("Billing cycle:")}</span>
        {@billing_provider.get_subscription_cycle(provider_subscription)}
      </div>
      <div>
        <span class="font-semibold">{gettext("Next charge:")}</span>
        {provider_subscription |> @billing_provider.get_subscription_next_charge() |> format_date()}
      </div>

      <div class="mt-5 flex justify-start gap-2">
        <.button
          label={gettext("Cancel subscription")}
          phx-click="cancel_subscription"
          color="danger"
          phx-disable-with={gettext("Loading...")}
          data-confirm={gettext("Are you sure?")}
        />

        <.button
          label={gettext("View plans")}
          link_type="live_redirect"
          to={@subscribe_path}
          color="light"
        />
      </div>
    </div>
    """
  end
end
