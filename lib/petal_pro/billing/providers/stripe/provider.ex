defmodule PetalPro.Billing.Providers.Stripe.Provider do
  @moduledoc """
  An interface to the Stripe API.

  Use this instead of StripityStripe directly because it allows you to mock responses in tests (thanks to mox).

  For example:

      alias PetalPro.Billing.Providers.Stripe.Provider

      expect(Provider, :create_checkout_session, fn _ ->
        mocked_session_response()
      end)
  """
  @behaviour PetalPro.Billing.Providers.Stripe.ProviderBehaviour

  @impl true
  def create_customer(params) do
    Stripe.Customer.create(params)
  end

  @impl true
  def create_portal_session(params) do
    Stripe.BillingPortal.Session.create(params)
  end

  @impl true
  def create_checkout_session(params) do
    Stripe.Checkout.Session.create(params)
  end

  @impl true
  def retrieve_product(stripe_product_id) do
    Stripe.Product.retrieve(stripe_product_id)
  end

  @impl true
  def list_subscriptions(params) do
    Stripe.Subscription.list(params)
  end

  @impl true
  def retrieve_subscription(provider_subscription_id) do
    Stripe.Subscription.retrieve(provider_subscription_id)
  end

  @impl true
  def cancel_subscription(id) do
    Stripe.Subscription.cancel(id)
  end
end
