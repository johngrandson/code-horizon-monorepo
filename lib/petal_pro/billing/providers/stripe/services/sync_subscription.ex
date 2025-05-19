defmodule PetalPro.Billing.Providers.Stripe.Services.SyncSubscription do
  @moduledoc """
  Syncs a Stripe subscription with the local database.
  Stripe is the source of truth.
  Use it when a subscription has been updated on Stripe and needs to be synced locally.
  Subscription type: https://hexdocs.pm/stripity_stripe/Stripe.Subscription.html#t:t/0
  """
  alias PetalPro.Billing.Customers
  alias PetalPro.Billing.Customers.Customer
  alias PetalPro.Billing.Providers.Stripe.Adapters.SubscriptionAdapter
  alias PetalPro.Billing.Subscriptions

  require Logger

  def call(%Stripe.Subscription{} = stripe_subscription) do
    Logger.info("Syncing #{stripe_subscription.id}")

    case {:customer, Customers.get_customer_by_provider_customer_id!(stripe_subscription.customer)} do
      {:customer, %Customer{} = customer} ->
        subscription_attrs =
          stripe_subscription
          |> SubscriptionAdapter.attrs_from_stripe_subscription()
          |> Map.put(:billing_customer_id, customer.id)

        case Subscriptions.get_subscription_by_provider_subscription_id(stripe_subscription.id) do
          nil ->
            subscription = Subscriptions.create_subscription!(subscription_attrs)

            Subscriptions.billing_lifecycle_action("billing.create_subscription", nil, nil, %{
              subscription: subscription,
              customer: customer
            })

            check_for_too_many_subscriptions(customer, subscription)

            :ok

          subscription ->
            {:ok, subscription} = Subscriptions.update_subscription(subscription, subscription_attrs)

            Subscriptions.billing_lifecycle_action("billing.update_subscription", nil, nil, %{
              subscription: subscription,
              customer: customer
            })

            :ok
        end

      error ->
        {:error, error}
    end
  end

  defp check_for_too_many_subscriptions(customer, subscription) do
    active_sub_count = Subscriptions.active_count(customer.id)

    # There should be only 1 active subscription per customer. It may be possible for a
    # user to make a second payment (e.g. they open 2 tabs, then purchase via each tab)
    if active_sub_count > 1 do
      Subscriptions.billing_lifecycle_action("billing.more_than_one_active_subscription_warning", nil, nil, %{
        subscription: subscription,
        customer: customer,
        active_subscriptions_count: active_sub_count
      })
    end
  end
end
