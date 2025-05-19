defmodule PetalPro.BillingFixtures do
  @moduledoc false
  import PetalPro.AccountsFixtures

  alias PetalPro.Billing.Customers
  alias PetalPro.Billing.Subscriptions

  def billing_customer_fixture(attrs \\ %{}) do
    user_id = attrs[:user_id] || confirmed_user_fixture().id
    source = attrs[:source] || :user
    provider_customer_id = attrs[:provider_customer_id] || "cus_PFDXVnCJHqastp"

    attrs =
      Enum.into(attrs, %{
        user_id: user_id,
        provider: "stripe",
        provider_customer_id: provider_customer_id,
        email: "petal_pro_test_user@example.com"
      })

    {:ok, customer} = Customers.create_customer_by_source(source, attrs)

    customer
  end

  def subscription_fixture(attrs \\ %{}) do
    billing_customer_id = attrs[:billing_customer_id] || billing_customer_fixture().id
    provider_subscription_id = attrs[:provider_subscription_id] || "sub_1OQrGyIWVkWpNCp709Y6qtlO"

    attrs =
      Enum.into(attrs, %{
        billing_customer_id: billing_customer_id
      })

    %{
      status: "active",
      plan_id: "stripe-test-plan-a-monthly",
      current_period_start: DateTime.utc_now(),
      provider_subscription_id: provider_subscription_id,
      provider_subscription_items: [
        %{price_id: "price_1OQj8pIWVkWpNCp74VstFtnd", product_id: "prod_PFDZyFfhgGUNOg"}
      ]
    }
    |> Map.merge(attrs)
    |> Subscriptions.create_subscription!()
  end
end
