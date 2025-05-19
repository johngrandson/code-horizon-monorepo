defmodule PetalPro.Billing.Subscriptions do
  @moduledoc false
  import Ecto.Query, warn: false

  alias PetalPro.Accounts
  alias PetalPro.Billing.Subscriptions.Subscription
  alias PetalPro.Logs
  alias PetalPro.Orgs
  alias PetalPro.Repo

  def list_subscriptions_query do
    from(s in Subscription, preload: [customer: [:user, :org]])
  end

  def get_subscription!(id), do: Repo.get!(Subscription, id)
  def get_subscription_by(attrs), do: Repo.get_by(Subscription, attrs)

  def get_subscription_by_provider_subscription_id(id) do
    Subscription
    |> Repo.get_by(provider_subscription_id: id)
    |> Repo.preload(:customer)
  end

  def get_active_subscription_by_customer_id(customer_id) do
    Subscription
    |> by_customer_id(customer_id)
    |> by_status(["active", "trialing"])
    |> order_by_period_desc()
    |> Repo.first()
  end

  def active_count(customer_id) do
    Subscription
    |> by_customer_id(customer_id)
    |> by_status(["active", "trialing"])
    |> Repo.count()
  end

  def create_subscription!(attrs \\ %{}) do
    %Subscription{}
    |> Subscription.changeset(attrs)
    |> Repo.insert!()
  end

  def cancel_subscription(%Subscription{} = subscription) do
    update_subscription(subscription, %{
      status: "canceled",
      canceled_at: NaiveDateTime.utc_now()
    })
  end

  def update_subscription(%Subscription{} = subscription, attrs) do
    subscription
    |> Subscription.changeset(attrs)
    |> Repo.update()
  end

  defp by_customer_id(query, customer_id) do
    from s in query, where: s.billing_customer_id == ^customer_id
  end

  defp by_status(query, statuses) when is_list(statuses) do
    from s in query, where: s.status in ^statuses
  end

  defp order_by_period_desc(query) do
    from s in query, order_by: [desc: s.current_period_start]
  end

  # Billing lifecyle actions - these allow you to hook into certain user events and do secondary tasks like create logs, send Slack messages etc.
  def billing_lifecycle_action(action, user, org, opts)

  def billing_lifecycle_action("billing.after_click_subscribe_button", user, org, %{
        plan: plan,
        customer: customer,
        billing_provider: billing_provider,
        billing_provider_session: billing_provider_session
      }) do
    PetalPro.Slack.message("""
    :scream_cat: #{user.name} has clicked a subscribe button for "#{plan.id}"...
    """)

    Logs.log_async("billing.after_click_subscribe_button", %{
      customer: customer,
      user: user,
      org: org,
      metadata: %{
        plan_id: plan.id,
        billing_provider: billing_provider,
        billing_provider_session_id: billing_provider_session.id
      }
    })
  end

  def billing_lifecycle_action("billing.create_subscription", user, org, %{subscription: subscription, customer: customer}) do
    slack_message("billing.create_subscription", customer, subscription)

    Logs.log_async("billing.create_subscription", %{
      customer: customer,
      user: user,
      org: org,
      metadata: %{
        subscription_id: subscription.id,
        plan_id: subscription.plan_id
      }
    })
  end

  def billing_lifecycle_action("billing.update_subscription", user, org, %{subscription: subscription, customer: customer}) do
    slack_message("billing.update_subscription", customer, subscription)

    Logs.log_async("billing.update_subscription", %{
      customer: customer,
      user: user,
      org: org,
      metadata: %{
        subscription_id: subscription.id,
        plan_id: subscription.plan_id
      }
    })
  end

  def billing_lifecycle_action("billing.cancel_subscription", user, org, %{subscription: subscription, customer: customer}) do
    PetalPro.Slack.message("""
    #{user.name} (##{user.id}) just cancelled a subscription for the plan: "#{subscription.plan_id}"
    """)

    Logs.log_async("billing.cancel_subscription", %{
      customer: customer,
      user: user,
      org: org,
      metadata: %{
        subscription_id: subscription.id,
        plan_id: subscription.plan_id
      }
    })
  end

  def billing_lifecycle_action("billing.more_than_one_active_subscription_warning", user, org, %{
        subscription: subscription,
        customer: customer,
        active_subscriptions_count: active_subscriptions_count
      }) do
    PetalPro.Slack.message("""
    :exclamation: *Customer #{customer.id} now has #{active_subscriptions_count} active subscriptions.* They may have been double charged. This is possible if Stripe processes multiple purchases in multiple tabs.
    Stripe Customer: #{customer.provider_customer_id}
    Stripe Subscription: #{subscription.provider_subscription_id}
    """)

    Logs.log_async("billing.more_than_one_active_subscription_warning", %{
      user: user,
      org: org,
      metadata: %{
        subscription_id: subscription.id,
        plan_id: subscription.plan_id
      }
    })
  end

  defp slack_message(action, customer, subscription)

  defp slack_message("billing.create_subscription", %{user_id: user_id, org_id: nil}, subscription) do
    user = Accounts.get_user!(user_id)

    PetalPro.Slack.message("""
    :moneybag: #{user.name} (##{user.id}) just purchased a subscription!
    **Plan:** "#{subscription.plan_id}"
    """)
  end

  defp slack_message("billing.create_subscription", %{user_id: nil, org_id: org_id}, subscription) do
    org = Orgs.get_org_by_id(org_id)

    PetalPro.Slack.message("""
    :moneybag: Subscription purchased for #{org.name} (##{org.id})!
    **Plan:** "#{subscription.plan_id}"
    """)
  end

  defp slack_message("billing.update_subscription", %{user_id: user_id, org_id: nil}, subscription) do
    user = Accounts.get_user!(user_id)

    PetalPro.Slack.message("""
    #{user.name} (##{user.id}) just updated a subscription for the plan: "#{subscription.plan_id}"
    """)
  end

  defp slack_message("billing.update_subscription", %{user_id: nil, org_id: org_id}, subscription) do
    org = Orgs.get_org_by_id(org_id)

    PetalPro.Slack.message("""
    Subscription updated for #{org.name} (##{org.id}). Plan: "#{subscription.plan_id}"
    """)
  end
end
