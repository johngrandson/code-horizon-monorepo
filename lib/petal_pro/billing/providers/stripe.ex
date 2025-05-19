defmodule PetalPro.Billing.Providers.Stripe do
  @moduledoc false
  use PetalPro.Billing.Providers.Behaviour

  alias PetalPro.Accounts.User
  alias PetalPro.Billing.Customers.Customer
  alias PetalPro.Billing.Plans
  alias PetalPro.Billing.Providers.Stripe.Provider
  alias PetalPro.Billing.Providers.Stripe.Services.CreateCheckoutSession
  alias PetalPro.Billing.Providers.Stripe.Services.CreatePortalSession
  alias PetalPro.Billing.Providers.Stripe.Services.FindOrCreateCustomer
  alias PetalPro.Billing.Providers.Stripe.Services.SyncCustomer
  alias PetalPro.Billing.Subscriptions.Subscription

  def checkout(%User{} = user, plan, source, source_id) do
    with {:ok, customer} <- FindOrCreateCustomer.call(user, source, source_id),
         {:ok, session} <-
           CreateCheckoutSession.call(%CreateCheckoutSession{
             customer_id: customer.id,
             source: source,
             source_id: source_id,
             provider_customer_id: customer.provider_customer_id,
             success_url: success_url(source, source_id, customer.id),
             cancel_url: cancel_url(source, source_id),
             allow_promotion_codes: plan.allow_promotion_codes,
             trial_period_days: Map.get(plan, :trial_days),
             line_items: plan.items
           }) do
      {:ok, customer, session}
    end
  end

  def checkout_url(session), do: session.url

  def change_plan(%Customer{} = customer, %Subscription{} = subscription, plan) do
    CreatePortalSession.call(
      customer,
      subscription,
      Plans.plan_items(plan)
    )
  end

  def subscription_adapter do
    PetalPro.Billing.Providers.Stripe.Adapters.SubscriptionAdapter
  end

  def sync_subscription(%Customer{} = customer) do
    SyncCustomer.call(customer)
  end

  def get_subscription_product(stripe_subscription) do
    get_subscription_item(stripe_subscription).price.product
  end

  def get_subscription_price(stripe_subscription) do
    get_subscription_item(stripe_subscription).price.unit_amount
  end

  def get_subscription_cycle(stripe_subscription) do
    get_subscription_item(stripe_subscription).plan.interval
  end

  def get_subscription_next_charge(stripe_subscription) do
    Util.unix_to_naive_datetime(stripe_subscription.current_period_end)
  end

  defp get_subscription_item(stripe_subscription) do
    List.first(stripe_subscription.items.data)
  end

  defdelegate retrieve_product(id), to: Provider
  defdelegate retrieve_subscription(id), to: Provider
  defdelegate cancel_subscription(id), to: Provider
end
