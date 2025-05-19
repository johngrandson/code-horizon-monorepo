defmodule PetalPro.Billing.SubscriptionsTest do
  use PetalPro.DataCase

  import PetalPro.AccountsFixtures
  import PetalPro.BillingFixtures

  alias PetalPro.Billing.Subscriptions

  describe "get_active_subscription_by_customer_id/2" do
    test "returns subscription" do
      user = user_fixture()
      customer = billing_customer_fixture(%{user_id: user.id})

      subscription_fixture(%{
        billing_customer_id: customer.id,
        provider_subscription_items: [
          %{price_id: "price1", product_id: "prod1"}
        ]
      })

      assert subscription = Subscriptions.get_active_subscription_by_customer_id(customer.id)
      assert subscription.status == "active"
    end

    test "returns nil, when no subscription exists" do
      user = user_fixture()
      customer = billing_customer_fixture(%{user_id: user.id})

      refute Subscriptions.get_active_subscription_by_customer_id(customer.id)
    end
  end
end
