defmodule PetalPro.Billing.Providers.Stripe.Services.CreatePortalSessionTest do
  use PetalProWeb.ConnCase

  import PetalPro.BillingFixtures

  alias PetalPro.Billing.Plans
  alias PetalPro.Billing.Providers.Stripe.Services.CreatePortalSession

  setup :register_and_sign_in_user

  test "call/3 for user as source", %{user: user} do
    Application.put_env(:petal_pro, :billing_entity, :user)

    customer = billing_customer_fixture(%{user_id: user.id, source: :user})
    subscription = subscription_fixture(%{billing_customer_id: customer.id})

    items =
      "stripe-test-plan-a-yearly"
      |> Plans.get_plan_by_id!()
      |> Plans.plan_items()

    use_cassette "PetalPro.Billing.Providers.Stripe.Services.CreatePortalSession.call user" do
      assert {:ok, %{url: "https://billing.stripe.com/p/session" <> _}} =
               CreatePortalSession.call(customer, subscription, items)
    end
  end

  test "call/3 for org as source", %{org: org} do
    Application.put_env(:petal_pro, :billing_entity, :org)

    customer = billing_customer_fixture(%{org_id: org.id, source: :org})
    subscription = subscription_fixture(%{billing_customer_id: customer.id})

    items =
      "stripe-test-plan-a-yearly"
      |> Plans.get_plan_by_id!()
      |> Plans.plan_items()

    use_cassette "PetalPro.Billing.Providers.Stripe.Services.CreatePortalSession.call org" do
      assert {:ok, %{url: "https://billing.stripe.com/p/session" <> _}} =
               CreatePortalSession.call(customer, subscription, items)
    end
  end
end
