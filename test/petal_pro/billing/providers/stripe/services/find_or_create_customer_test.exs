defmodule PetalPro.Billing.Providers.Stripe.Services.FindOrCreateCustomerTest do
  use PetalPro.DataCase

  import PetalPro.AccountsFixtures
  import PetalPro.BillingFixtures

  alias PetalPro.Billing.Customers.Customer
  alias PetalPro.Billing.Providers.Stripe.Services.FindOrCreateCustomer
  alias PetalPro.Repo

  describe "call/3" do
    test "finds a customer" do
      user = confirmed_user_fixture()

      billing_customer_fixture(%{user_id: user.id})

      assert Repo.count(Customer) == 1

      assert {:ok, %Customer{}} = FindOrCreateCustomer.call(user, :user, user.id)

      assert Repo.count(Customer) == 1
    end

    test "creates a customer" do
      user = confirmed_user_fixture()

      assert Repo.count(Customer) == 0

      use_cassette "PetalPro.Billing.Providers.Stripe.Services.FindOrCreateCustomer.call" do
        assert {:ok, %Customer{}} = FindOrCreateCustomer.call(user, :user, user.id)
      end

      assert Repo.count(Customer) == 1
    end
  end
end
