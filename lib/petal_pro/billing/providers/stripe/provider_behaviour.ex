defmodule PetalPro.Billing.Providers.Stripe.ProviderBehaviour do
  @moduledoc false
  @type params :: map()
  @type id :: Stripe.id()
  @type customer :: Stripe.Customer.t()
  @type session :: Stripe.Checkout.Session.t()
  @type product :: Stripe.Product.t()
  @type subscription :: Stripe.Subscription.t()
  @type error :: Stripe.Error.t()

  @callback create_customer(params) :: {:ok, customer} | {:error, error}
  @callback create_portal_session(params) :: {:ok, session} | {:error, error}
  @callback create_checkout_session(params) :: {:ok, session} | {:error, error}
  @callback retrieve_product(id) :: {:ok, product} | {:error, error}
  @callback list_subscriptions(params) :: {:ok, product} | {:error, error}
  @callback retrieve_subscription(id) :: {:ok, subscription} | {:error, error}
  @callback cancel_subscription(id) :: {:ok, subscription} | {:error, error}
end
