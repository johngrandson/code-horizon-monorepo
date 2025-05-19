defmodule PetalProWeb.AdminDashboardLive do
  @moduledoc false
  use PetalProWeb, :live_view

  import PetalProWeb.AdminLayoutComponent
  import PetalProWeb.Components.DashboardComponents

  alias PetalPro.Accounts.UserQuery
  alias PetalPro.Orgs.Org
  alias PetalPro.Repo
  alias PetalProWeb.AdminChartDataHelper

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket),
      do: Phoenix.PubSub.subscribe(PetalPro.PubSub, "admin_dashboard:stats")

    socket =
      socket
      |> assign(:interval, "month")
      |> assign_last_joined_users()
      |> push_users_data()
      |> push_orgs_data()
      |> push_subscribed_data()
      |> push_user_acquisition_data()
      |> push_org_acquisition_data()
      |> push_subscriber_acquisition_data()
      |> push_active_subscriptions_data()

    {:ok, socket}
  end

  defp push_users_data(socket) do
    users_data = AdminChartDataHelper.get_this_month_and_last_months_data(UserQuery.active?())

    socket
    |> push_event("users_data", users_data)
    |> assign(:user_empty?, users_data.empty?)
    |> assign(:user_percentage_change, users_data.percentage_change)
    |> assign(:user_total_for_this_month, users_data.total_for_this_month)
  end

  defp push_orgs_data(socket) do
    orgs_data = AdminChartDataHelper.get_this_month_and_last_months_data(Org)

    socket
    |> push_event("orgs_data", orgs_data)
    |> assign(:org_empty?, orgs_data.empty?)
    |> assign(:org_percentage_change, orgs_data.percentage_change)
    |> assign(:org_total_for_this_month, orgs_data.total_for_this_month)
  end

  defp push_subscribed_data(socket) do
    subscribed_data =
      UserQuery.active?()
      |> UserQuery.subscribed_to_marketing_notifications?(true)
      |> AdminChartDataHelper.get_this_month_and_last_months_data()

    socket
    |> push_event("newsletter_subscribed_data", subscribed_data)
    |> assign(:subscribed_empty?, subscribed_data.empty?)
    |> assign(:subscribed_percentage_change, subscribed_data.percentage_change)
    |> assign(:subscribed_total_for_this_month, subscribed_data.total_for_this_month)
  end

  defp push_user_acquisition_data(socket) do
    users_data = AdminChartDataHelper.get_this_year_and_last_years_data(UserQuery.active?())

    socket
    |> push_event("user_acquisitions", users_data)
    |> assign(:user_acquisitions_empty?, users_data.empty?)
  end

  defp push_org_acquisition_data(socket) do
    orgs_data = AdminChartDataHelper.get_this_year_and_last_years_data(Org)

    socket
    |> push_event("org_acquisitions", orgs_data)
    |> assign(:org_acquisitions_empty?, orgs_data.empty?)
  end

  defp push_subscriber_acquisition_data(socket) do
    subscribed_query = UserQuery.subscribed_to_marketing_notifications?(UserQuery.active?(), true)
    subscribed_data = AdminChartDataHelper.get_this_year_and_last_years_data(subscribed_query)

    socket
    |> push_event("newsletter_subscriber_acquisitions", subscribed_data)
    |> assign(:newsletter_subscriber_acquisitions_empty?, subscribed_data.empty?)
  end

  defp push_active_subscriptions_data(socket) do
    active_subscriptions_data = AdminChartDataHelper.get_active_subscriptions()

    socket
    |> push_event("paying_subscriptions", active_subscriptions_data)
    |> assign(:paying_active_subscriptions_empty?, active_subscriptions_data.empty?)
  end

  defp assign_last_joined_users(socket) do
    last_joined_users =
      UserQuery.active?()
      |> UserQuery.order_by(desc: :inserted_at)
      |> UserQuery.limit(5)
      |> Repo.all()

    assign(socket, :last_joined_users, last_joined_users)
  end

  @impl true
  def handle_info("admin_stats", socket) do
    {:noreply,
     socket
     |> assign_last_joined_users()
     |> push_users_data()
     |> push_orgs_data()
     |> push_subscribed_data()
     |> push_user_acquisition_data()
     |> push_org_acquisition_data()
     |> push_subscriber_acquisition_data()
     |> push_active_subscriptions_data()}
  end

  def notify_admin_stats, do: Phoenix.PubSub.broadcast(PetalPro.PubSub, "admin_dashboard:stats", "admin_stats")
end
