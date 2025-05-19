defmodule PetalPro.Billing.ProductsTest do
  use PetalPro.DataCase

  alias PetalPro.Billing.Plans
  alias PetalPro.Billing.Subscriptions.Subscription

  doctest Plans

  test "get_plan_by_id!/1" do
    assert %{id: "plan1-1"} = Plans.get_plan_by_id!("plan1-1")

    assert_raise RuntimeError, "No plan found for id plan1-2", fn ->
      Plans.get_plan_by_id!("plan1-2")
    end
  end

  test "get_plan_by_subscription!/1" do
    assert %{id: "plan1-1"} = Plans.get_plan_by_subscription!(%Subscription{plan_id: "plan1-1"})

    assert_raise RuntimeError, "No plan found for id plan1-2", fn ->
      Plans.get_plan_by_subscription!(%Subscription{plan_id: "plan1-2"})
    end
  end

  test "get_plan_by_stripe_subscription/2" do
    assert %{id: "plan1-1"} =
             Plans.get_plan_by_stripe_subscription(%Stripe.Subscription{items: %{data: [%{price: %{id: "item1-1-1"}}]}})

    assert %{id: "plan2-2"} =
             Plans.get_plan_by_stripe_subscription(%Stripe.Subscription{
               items: %{data: [%{price: %{id: "item2-1-1"}}, %{price: %{id: "item2-2-1"}}]}
             })

    assert %{id: "plan2-2"} =
             Plans.get_plan_by_stripe_subscription(%Stripe.Subscription{items: %{data: [%{price: %{id: "item2-2-1"}}]}})

    refute Plans.get_plan_by_stripe_subscription(%Stripe.Subscription{items: %{data: [%{price: %{id: "item2-2-2"}}]}})
  end
end
