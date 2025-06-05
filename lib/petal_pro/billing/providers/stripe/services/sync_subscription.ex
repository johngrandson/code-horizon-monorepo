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
  alias PetalPro.Orgs

  require Logger

  def call(%Stripe.Subscription{} = stripe_subscription) do
    Logger.info("Syncing subscription #{stripe_subscription.id}")

    case {:customer, Customers.get_customer_by_provider_customer_id!(stripe_subscription.customer)} do
      {:customer, %Customer{} = customer} ->
        subscription_attrs =
          stripe_subscription
          |> SubscriptionAdapter.attrs_from_stripe_subscription()
          |> Map.put(:billing_customer_id, customer.id)
          # Ensure plan_id is a string if it's an atom
          |> update_in([:plan_id], &if(is_atom(&1), do: to_string(&1), else: &1))

        case Subscriptions.get_subscription_by_provider_subscription_id(stripe_subscription.id) do
          nil ->
            subscription = Subscriptions.create_subscription!(subscription_attrs)

            update_org_plan(customer, subscription)

            Subscriptions.billing_lifecycle_action("billing.create_subscription", nil, nil, %{
              subscription: subscription,
              customer: customer
            })

            check_for_too_many_subscriptions(customer, subscription)
            :ok

          subscription ->
            {:ok, subscription} = Subscriptions.update_subscription(subscription, subscription_attrs)
            update_org_plan(customer, subscription)

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

  defp update_org_plan(%Customer{org_id: org_id}, subscription)
       when not is_nil(org_id) and not is_nil(subscription.plan_id) do
    case Orgs.get_org_by_id(org_id) do
      nil ->
        Logger.warning("Could not find org with id: #{inspect(org_id)}")
        :ok

      org ->
        # Map Stripe plan IDs to Org plan enums
        plan_enum =
          case subscription.plan_id do
            plan_id when plan_id in ["essential-monthly", "essential_monthly", "essential-yearly", "essential_yearly"] ->
              :starter

            plan_id when plan_id in ["business-monthly", "business_monthly", "business-yearly", "business_yearly"] ->
              :professional

            plan_id
            when plan_id in ["enterprise-monthly", "enterprise_monthly", "enterprise-yearly", "enterprise_yearly"] ->
              :enterprise

            # Default to free if no match
            _ ->
              :free
          end

        Logger.info("Updating org #{org.id} plan to #{plan_enum} (from subscription plan_id: #{subscription.plan_id})")

        case Orgs.update_org(org, %{plan: plan_enum}) do
          {:ok, _updated_org} ->
            :ok

          {:error, changeset} ->
            Logger.error("Failed to update org plan: #{inspect(changeset.errors)}")
            :error
        end
    end
  end

  defp update_org_plan(_customer, _subscription), do: :ok

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
