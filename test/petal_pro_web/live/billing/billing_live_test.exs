defmodule PetalProWeb.BillingLiveTest do
  use PetalProWeb.ConnCase

  import PetalPro.BillingFixtures
  import Phoenix.LiveViewTest

  alias PetalPro.Billing.Providers.Stripe.Provider
  alias PetalPro.Billing.Subscriptions

  setup :register_and_sign_in_user

  describe "user as source" do
    setup %{user: user} do
      Application.put_env(:petal_pro, :billing_entity, :user)

      customer = billing_customer_fixture(%{user_id: user.id})

      subscription_fixture(%{billing_customer_id: customer.id})

      [customer: customer]
    end

    test "shows current subscription", %{conn: conn} do
      vcr_name = "PetalProWeb.BillingLive user show"

      use_cassette vcr_name do
        assert {:ok, view, html} = live(conn, ~p"/app/billing")
        assert html =~ "Billing"
        assert html =~ "spinner"

        async_html = render_async(view, async_timeout(vcr_name))

        assert async_html =~ "$1.99"
        assert async_html =~ "Petal Pro Test Plan A"
        assert async_html =~ "month"
      end
    end

    test "cancels current subscription", %{conn: conn, customer: customer} do
      vcr_name = "PetalProWeb.BillingLive user cancel"

      use_cassette vcr_name do
        expect(Provider, :cancel_subscription, fn _ ->
          {:ok, stripe_subscription} = Provider.retrieve_subscription("sub_1OQrGyIWVkWpNCp709Y6qtlO")

          {:ok, Map.put(stripe_subscription, :status, "canceled")}
        end)

        assert Subscriptions.active_count(customer.id) == 1

        assert {:ok, view, _html} = live(conn, ~p"/app/billing")

        vcr_name
        |> async_timeout()
        |> Process.sleep()

        render_click(view, "cancel_subscription", %{})

        {:ok, view, _html} = live(conn, ~p"/app/billing")

        async_html = render_async(view, async_timeout(vcr_name))

        assert async_html =~ "No active subscription"
        assert Subscriptions.active_count(customer.id) == 0
      end
    end
  end

  describe "org as source" do
    setup %{org: org} do
      Application.put_env(:petal_pro, :billing_entity, :org)

      customer = billing_customer_fixture(%{org_id: org.id, source: :org})

      subscription_fixture(%{billing_customer_id: customer.id})

      [customer: customer]
    end

    test "shows current subscription", %{conn: conn, org: org} do
      vcr_name = "PetalProWeb.BillingLive org show"

      use_cassette vcr_name do
        assert {:ok, view, html} = live(conn, ~p"/app/org/#{org.slug}/billing")
        assert html =~ "Billing"
        assert html =~ "spinner"

        async_html = render_async(view, async_timeout(vcr_name))

        assert async_html =~ "$1.99"
        assert async_html =~ "Petal Pro Test Plan A"
        assert async_html =~ "month"
      end
    end

    test "cancels current subscription", %{conn: conn, org: org, customer: customer} do
      vcr_name = "PetalProWeb.BillingLive org cancel"

      use_cassette vcr_name do
        expect(Provider, :cancel_subscription, fn _ ->
          {:ok, stripe_subscription} = Provider.retrieve_subscription("sub_1OQrGyIWVkWpNCp709Y6qtlO")

          {:ok, Map.put(stripe_subscription, :status, "canceled")}
        end)

        assert Subscriptions.active_count(customer.id) == 1

        assert {:ok, view, _html} = live(conn, ~p"/app/org/#{org.slug}/billing")

        vcr_name
        |> async_timeout()
        |> Process.sleep()

        render_click(view, "cancel_subscription", %{})

        {:ok, view, _html} = live(conn, ~p"/app/org/#{org.slug}/billing")

        async_html = render_async(view, async_timeout(vcr_name))

        assert async_html =~ "No active subscription"
        assert Subscriptions.active_count(customer.id) == 0
      end
    end
  end

  defp async_timeout(name) do
    if in_vcr?(name), do: 100, else: 2_000
  end
end
