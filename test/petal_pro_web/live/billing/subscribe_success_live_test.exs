defmodule PetalProWeb.SubscribeSuccessLiveTest do
  use PetalProWeb.ConnCase, async: true

  import PetalPro.BillingFixtures
  import Phoenix.LiveViewTest

  setup :register_and_sign_in_user

  describe "live /app/subscribe/success" do
    setup %{user: user} do
      customer =
        billing_customer_fixture(%{source: :user, user_id: user.id})

      {:ok, customer: customer}
    end

    test "when subscription creation is successful, show a success message", %{
      conn: conn,
      customer: customer
    } do
      subscription_fixture(%{
        billing_customer_id: customer.id,
        plan_id: "something",
        provider_subscription_items: [
          %{price_id: "price1", product_id: "prod1"}
        ]
      })

      {:ok, _view, html} =
        live(conn, ~p"/app/subscribe/success?customer_id=#{customer.id}&plan_id=something")

      assert html =~ "Thank you for joining us!"
    end

    test "when waiting for the webhook to complete, show a spinner", %{conn: conn, customer: customer} do
      {:ok, view, _html} =
        live(conn, ~p"/app/subscribe/success?customer_id=#{customer.id}&plan_id=something")

      assert view
             |> element("#subscription-status")
             |> render() =~ "spinner"
    end

    test "check_subscription() will toggle a success message if it finds a subscription",
         %{conn: conn, customer: customer} do
      {:ok, view, _html} =
        live(conn, ~p"/app/subscribe/success?customer_id=#{customer.id}&plan_id=something")

      subscription_fixture(%{
        billing_customer_id: customer.id,
        plan_id: "something",
        provider_subscription_items: [
          %{price_id: "price1", product_id: "prod1"}
        ]
      })

      send(view.pid, :check_subscription)

      assert view
             |> element("#subscription-status")
             |> render() =~ "Thank you for joining us!"
    end

    test "when a subscription fails, show a failure message", %{conn: conn, customer: customer} do
      {:ok, view, _html} =
        live(conn, ~p"/app/subscribe/success?customer_id=#{customer.id}&plan_id=something")

      send(view.pid, :check_subscription)
      send(view.pid, :check_subscription)
      send(view.pid, :check_subscription)
      send(view.pid, :check_subscription)
      send(view.pid, :check_subscription)

      assert view
             |> element("#subscription-status")
             |> render() =~ "Subscription failed. Please contact support."
    end
  end

  describe "live /app/org/:org_slug/subscribe/success" do
    setup %{org: org} do
      customer = billing_customer_fixture(%{source: :org, org_id: org.id})

      {:ok, customer: customer}
    end

    test "when subscription creation is successful, show a success message", %{
      conn: conn,
      customer: customer,
      org: org
    } do
      subscription_fixture(%{
        billing_customer_id: customer.id,
        plan_id: "something",
        provider_subscription_items: [
          %{price_id: "price1", product_id: "prod1"}
        ]
      })

      {:ok, _view, html} =
        live(
          conn,
          ~p"/app/org/#{org.slug}/subscribe/success?customer_id=#{customer.id}&plan_id=something"
        )

      assert html =~ "Thank you for joining us!"
    end

    test "when waiting for the webhook to complete, show a spinner", %{conn: conn, customer: customer, org: org} do
      {:ok, view, _html} =
        live(
          conn,
          ~p"/app/org/#{org.slug}/subscribe/success?customer_id=#{customer.id}&plan_id=something"
        )

      assert view
             |> element("#subscription-status")
             |> render() =~ "spinner"
    end

    test "check_subscription() will toggle a success message if it finds a subscription",
         %{conn: conn, org: org, customer: customer} do
      {:ok, view, _html} =
        live(
          conn,
          ~p"/app/org/#{org.slug}/subscribe/success?customer_id=#{customer.id}&plan_id=something"
        )

      subscription_fixture(%{
        billing_customer_id: customer.id,
        plan_id: "something",
        provider_subscription_items: [
          %{price_id: "price1", product_id: "prod1"}
        ]
      })

      send(view.pid, :check_subscription)

      assert view
             |> element("#subscription-status")
             |> render() =~ "Thank you for joining us!"
    end

    test "when a subscription fails, show a failure message", %{conn: conn, customer: customer, org: org} do
      {:ok, view, _html} =
        live(
          conn,
          ~p"/app/org/#{org.slug}/subscribe/success?customer_id=#{customer.id}&plan_id=something"
        )

      send(view.pid, :check_subscription)
      send(view.pid, :check_subscription)
      send(view.pid, :check_subscription)
      send(view.pid, :check_subscription)
      send(view.pid, :check_subscription)

      assert view
             |> element("#subscription-status")
             |> render() =~ "Subscription failed. Please contact support."
    end
  end
end
