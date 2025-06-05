defmodule PetalPro.Billing.Providers.Stripe.Services.SyncCustomer do
  @moduledoc false
  alias PetalPro.Billing.Providers.Stripe.Provider
  alias PetalPro.Billing.Providers.Stripe.Services.SyncSubscription

  require Logger

  def call(customer) do
    Logger.info("Syncing customer #{customer.id}...")

    case Provider.list_subscriptions(%{customer: customer.provider_customer_id, status: :all}) do
      {:ok, %{data: stripe_subscriptions} = _response} when is_list(stripe_subscriptions) ->
        Enum.each(stripe_subscriptions, &SyncSubscription.call/1)
        Logger.info("Customer #{customer.id}: #{length(stripe_subscriptions)} subscriptions found and synced.")
        :ok

      {:error, %Stripe.Error{message: message} = error} ->
        Logger.error("Stripe error syncing customer #{customer.id}: #{message}")
        {:error, error}
    end
  end
end
