defmodule PetalProWeb.SubscribeLiveTest do
  use PetalProWeb.ConnCase

  import PetalPro.BillingFixtures
  import Phoenix.LiveViewTest

  setup :register_and_sign_in_user

  @plan_id "stripe-test-plan-a-monthly"
  @other_plan_id "stripe-test-plan-a-yearly"

  describe "/app/subscribe" do
    setup %{user: user} do
      Application.put_env(:petal_pro, :billing_entity, :user)

      customer = billing_customer_fixture(%{user_id: user.id})
      subscription_fixture(%{billing_customer_id: customer.id})

      {:ok, customer: customer}
    end

    test "lists available plans to subscribe", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/app/subscribe")

      assert html =~ "Prod 1"
      assert html =~ "Prod 2"
    end

    test "upon clicking a 'Subscribe' button, the current user should be redirected to checkout", %{
      conn: conn
    } do
      {:ok, view, _html} = live(conn, ~p"/app/subscribe")

      render_click(view, "checkout", %{"plan" => @plan_id})

      assert_redirected(view, "/app/checkout/#{@plan_id}")
    end

    test "when the current user is already subscribed, the 'Cancel' button should be shown", %{
      conn: conn
    } do
      {:ok, view, _html} = live(conn, ~p"/app/subscribe")

      assert view |> element("a", "Cancel") |> render() =~ "/app/billing"
    end

    test "when the current user is already subscribed, the 'Switch' buttons should be clickable", %{
      conn: conn
    } do
      {:ok, view, _html} = live(conn, ~p"/app/subscribe")

      refute view |> element("#pricing-plan-#{@other_plan_id} button") |> render() =~
               "disabled"
    end

    test "when a 'Switch' button is clicked, the user should be redirected to the Stripe portal to update the plan",
         %{
           conn: conn
         } do
      use_cassette "PetalProWeb.SubscribeLive user switch plan" do
        {:ok, view, _html} = live(conn, ~p"/app/subscribe")

        assert {:error, {:redirect, %{to: redirected_to_stripe_url}}} =
                 view
                 |> element("#pricing-plan-#{@other_plan_id} button")
                 |> render_click()

        assert redirected_to_stripe_url =~ "https://billing.stripe.com/p/session/"
      end
    end
  end

  describe "/app/org/:org_slug/subscribe" do
    setup %{org: org} do
      Application.put_env(:petal_pro, :billing_entity, :org)

      customer = billing_customer_fixture(%{source: :org, org_id: org.id})

      subscription =
        subscription_fixture(%{
          billing_customer_id: customer.id,
          plan_id: @plan_id,
          provider_subscription_items: [
            %{price_id: "price1", product_id: "prod1"}
          ]
        })

      {:ok, customer: customer, subscription: subscription}
    end

    test "lists available plans to subscribe", %{conn: conn, org: org} do
      {:ok, _view, html} = live(conn, ~p"/app/org/#{org.slug}/subscribe")

      assert html =~ "Prod 1"
      assert html =~ "Prod 2"
    end

    test "upon clicking a 'Subscribe' button, the current user should be redirected to checkout", %{
      conn: conn,
      org: org
    } do
      {:ok, view, _html} = live(conn, ~p"/app/org/#{org.slug}/subscribe")

      render_click(view, "checkout", %{"plan" => @plan_id})

      assert_redirected(view, "/app/org/#{org.slug}/checkout/#{@plan_id}")
    end

    test "when the current user is already subscribed, the 'Cancel' button should be shown",
         %{conn: conn, org: org} do
      {:ok, view, _html} = live(conn, ~p"/app/org/#{org.slug}/subscribe")

      assert view |> element("a", "Cancel") |> render() =~ "/app/org/#{org.slug}/billing"
    end

    test "when the current user is already subscribed, the 'Switch' buttons should be clickable",
         %{conn: conn, org: org} do
      {:ok, view, _html} = live(conn, ~p"/app/org/#{org.slug}/subscribe")

      refute view |> element("#pricing-plan-#{@other_plan_id} button") |> render() =~
               "disabled"
    end

    test "when a 'Switch' button is clicked, the current user should be redirected to the Stripe portal to update the plan",
         %{conn: conn, org: org} do
      use_cassette "PetalProWeb.SubscribeLive org switch plan" do
        {:ok, view, _html} = live(conn, ~p"/app/org/#{org.slug}/subscribe")

        assert {:error, {:redirect, %{to: redirected_to_stripe_url}}} =
                 view
                 |> element("#pricing-plan-#{@other_plan_id} button")
                 |> render_click()

        assert redirected_to_stripe_url =~ "https://billing.stripe.com/p/session/"
      end
    end
  end
end
