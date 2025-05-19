defmodule PetalPro.Billing.Providers.Stripe.Services.SyncCustomer do
  @moduledoc false
  alias PetalPro.Billing.Providers.Stripe.Provider
  alias PetalPro.Billing.Providers.Stripe.Services.SyncSubscription

  require Logger

  def call(customer) do
    Logger.info("Syncing customer #{customer.id}...")

    {:ok, %{data: stripe_subscriptions}} =
      Provider.list_subscriptions(%{customer: customer.provider_customer_id, status: :all})

    Enum.each(stripe_subscriptions, fn stripe_subscription ->
      SyncSubscription.call(stripe_subscription)
    end)

    Logger.info("Customer #{customer.id}: #{length(stripe_subscriptions)} subscriptions found and synced.")

    :ok
  end
end
