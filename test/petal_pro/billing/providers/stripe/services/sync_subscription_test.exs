defmodule PetalPro.Billing.Providers.Stripe.Services.SyncSubscriptionTest do
  use PetalPro.DataCase

  import PetalPro.AccountsFixtures
  import PetalPro.BillingFixtures
  import PetalPro.OrgsFixtures

  alias PetalPro.Billing.Providers.Stripe.Services.SyncSubscription
  alias PetalPro.Billing.Subscriptions

  describe "call/1 for user as source" do
    setup do
      Application.put_env(:petal_pro, :billing_entity, :user)

      user = confirmed_user_fixture()

      %{provider_customer_id: provider_customer_id} =
        billing_customer_fixture(%{user_id: user.id})

      [
        stripe_subscription: %Stripe.Subscription{
          id: "sub_1OQrGyIWVkWpNCp709Y6qtlO",
          customer: provider_customer_id,
          status: "active",
          current_period_start: DateTime.to_unix(DateTime.utc_now()),
          items: %{
            data: [
              %{
                price: %{
                  id: "price_1OQj8pIWVkWpNCp74VstFtnd",
                  product: "prod_PFDZyFfhgGUNOg"
                }
              }
            ]
          },
          metadata: %{
            source: :user,
            source_id: user.id
          }
        }
      ]
    end

    test "creates a new subscription if one doesn't exist", %{stripe_subscription: stripe_subscription} do
      test_new_subscription(stripe_subscription)
    end

    test "updates an existing subscription if one exists", %{stripe_subscription: stripe_subscription} do
      test_existing_subscription(stripe_subscription)
    end
  end

  describe "call/1 for org as source" do
    setup do
      Application.put_env(:petal_pro, :billing_entity, :org)

      org = org_fixture()

      %{provider_customer_id: provider_customer_id} =
        billing_customer_fixture(%{org_id: org.id, source: :org})

      [
        stripe_subscription: %Stripe.Subscription{
          id: "sub_1OQrGyIWVkWpNCp709Y6qtlO",
          customer: provider_customer_id,
          status: "active",
          current_period_start: DateTime.to_unix(DateTime.utc_now()),
          items: %{
            data: [
              %{
                price: %{
                  id: "price_1OQj8pIWVkWpNCp74VstFtnd",
                  product: "prod_PFDZyFfhgGUNOg"
                }
              }
            ]
          },
          metadata: %{
            source: :org,
            source_id: org.id
          }
        }
      ]
    end

    test "creates a new subscription if one doesn't exist", %{stripe_subscription: stripe_subscription} do
      test_new_subscription(stripe_subscription)
    end

    test "updates an existing subscription if one exists", %{stripe_subscription: stripe_subscription} do
      test_existing_subscription(stripe_subscription)
    end
  end

  defp test_new_subscription(stripe_subscription) do
    refute Subscriptions.get_subscription_by_provider_subscription_id(stripe_subscription.id)

    SyncSubscription.call(stripe_subscription)

    subscription = Subscriptions.get_subscription_by_provider_subscription_id(stripe_subscription.id)

    assert subscription.provider_subscription_id == stripe_subscription.id
    assert subscription.customer.provider_customer_id == stripe_subscription.customer
    assert List.first(subscription.provider_subscription_items)["price_id"] == "price_1OQj8pIWVkWpNCp74VstFtnd"
  end

  defp test_existing_subscription(stripe_subscription) do
    SyncSubscription.call(stripe_subscription)

    assert subscription = Subscriptions.get_subscription_by_provider_subscription_id(stripe_subscription.id)

    new_stripe_subscription = %Stripe.Subscription{
      stripe_subscription
      | items: %{
          data: [
            %{
              price: %{
                id: "price_1OQj8TIWVkWpNCp7ZlUSOaI9",
                product: "prod_PFDZyFfhgGUNOg"
              }
            }
          ]
        }
    }

    SyncSubscription.call(new_stripe_subscription)

    new_subscription = Subscriptions.get_subscription_by_provider_subscription_id(new_stripe_subscription.id)

    assert new_subscription.id == subscription.id
    assert List.first(new_subscription.provider_subscription_items)["price_id"] == "price_1OQj8TIWVkWpNCp7ZlUSOaI9"
  end
end
