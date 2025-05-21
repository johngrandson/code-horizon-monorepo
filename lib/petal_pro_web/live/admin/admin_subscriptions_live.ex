defmodule PetalProWeb.AdminSubscriptionsLive do
  @moduledoc false
  use PetalProWeb, :live_view

  import PetalProWeb.AdminLayoutComponent

  alias PetalPro.Accounts.User
  alias PetalPro.Billing.Customers.Customer
  alias PetalPro.Billing.Subscriptions
  alias PetalPro.Billing.Subscriptions.Subscription
  alias PetalPro.Orgs.Org
  alias PetalProWeb.DataTable

  @data_table_opts [
    default_order: [
      order_by: [:id, :inserted_at],
      order_directions: [:asc, :asc]
    ],
    default_limit: 20,
    default_pagination_type: :page
  ]

  @subscription_link PetalPro.config(:billing_provider_subscription_link)

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: "Subscriptions")}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {subscriptions, meta} = DataTable.search(Subscriptions.list_subscriptions_query(), params, @data_table_opts)

    {:noreply, assign(socket, %{subscriptions: subscriptions, meta: meta})}
  end

  @impl true
  def handle_event("update_filters", %{"filters" => filter_params}, socket) do
    query_params = build_filter_params(socket.assigns.meta, filter_params)
    {:noreply, push_patch(socket, to: ~p"/admin/subscriptions?#{query_params}")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.admin_layout current_page={:admin_subscriptions} current_user={@current_user}>
      <.page_header
        title={gettext("Subscriptions")}
        description={gettext("Manage all the subscriptions")}
      />

      <.data_table meta={@meta} items={@subscriptions}>
        <:col field={:id} sortable />
        <:col :let={subscription} field={:customer}>
          {customer_name(subscription.customer)}
        </:col>
        <:col :let={subscription} label="Type">
          {customer_type(subscription.customer)}
        </:col>
        <:col field={:status} sortable filterable={[:=~]} />
        <:col field={:plan_id} sortable filterable={[:=~]} />
        <:col field={:current_period_start} />
        <:col field={:current_period_end_at} />
        <:col :let={subscription} field={:actions}>
          <.link
            target="_blank"
            href={provider_link(subscription)}
            class="inline-flex hover:underline"
          >
            Open <.icon name="hero-arrow-top-right-on-square" class="ml-1 w-4 h-4" />
          </.link>
        </:col>
      </.data_table>
    </.admin_layout>
    """
  end

  defp provider_link(%Subscription{customer: %Customer{provider: "stripe"}} = subscription) do
    @subscription_link <> subscription.provider_subscription_id
  end

  defp customer_name(%Customer{org: %Org{} = org}), do: org.name
  defp customer_name(%Customer{user: %User{} = user}), do: user.name

  defp customer_type(%Customer{org: %Org{}}), do: "org"
  defp customer_type(%Customer{user: %User{}}), do: "user"
end
