defmodule PetalProWeb.SubscribeControllerTest do
  use PetalProWeb.ConnCase

  setup :register_and_sign_in_user

  describe "GET /app/checkout/:plan_slug" do
    test "as an org", %{conn: conn, org: org} do
      use_cassette "PetalProWeb.SubscribeController.checkout org" do
        assert conn
               |> get(~p"/app/org/#{org.slug}/checkout/stripe-test-plan-a-monthly", %{})
               |> redirected_to() =~ "https://checkout.stripe.com/c/pay/"
      end
    end
  end
end
