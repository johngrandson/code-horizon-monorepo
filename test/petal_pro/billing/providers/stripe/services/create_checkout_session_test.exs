defmodule PetalPro.Billing.Providers.Stripe.Services.CreateCheckoutSessionTest do
  use PetalPro.DataCase

  import PetalPro.AccountsFixtures
  import PetalPro.BillingFixtures

  alias PetalPro.Billing.Plans
  alias PetalPro.Billing.Providers.Stripe.Services.CreateCheckoutSession

  describe "call/1" do
    test "creates a checkout session" do
      user = confirmed_user_fixture()
      customer = billing_customer_fixture(%{user_id: user.id})
      email = customer.email
      plan = Plans.get_plan_by_id!("stripe-test-plan-a-monthly")

      use_cassette "PetalPro.Billing.Providers.Stripe.Services.CreateCheckoutSession.call" do
        assert {:ok,
                %Stripe.Checkout.Session{
                  customer_details: %{
                    email: ^email
                  }
                }} =
                 CreateCheckoutSession.call(%CreateCheckoutSession{
                   customer_id: customer.id,
                   source: :user,
                   source_id: user.id,
                   provider_customer_id: customer.provider_customer_id,
                   success_url: "http://example.com",
                   cancel_url: "http://example.com",
                   allow_promotion_codes: true,
                   trial_period_days: Map.get(plan, :trial_days),
                   line_items: plan.items
                 })
      end
    end
  end
end
