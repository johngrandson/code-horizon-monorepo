defmodule PetalPro.Billing.Providers.Stripe.Services.CreatePortalSession do
  @moduledoc false
  use PetalProWeb, :verified_routes

  alias PetalPro.Billing.Customers
  alias PetalPro.Billing.Customers.Customer
  alias PetalPro.Billing.Providers.Behaviour.UrlHelpers
  alias PetalPro.Billing.Providers.Stripe.Provider
  alias PetalPro.Billing.Subscriptions.Subscription

  def call(%Customer{} = customer, %Subscription{} = subscription, items) do
    subscription_item_id =
      subscription.provider_subscription_id
      |> Provider.retrieve_subscription()
      |> then(fn {:ok, stripe_subscription} -> stripe_subscription end)
      |> get_subscription_item()

    Provider.create_portal_session(%{
      customer: customer.provider_customer_id,
      flow_data: %{
        type: :subscription_update_confirm,
        subscription_update_confirm: %{
          subscription: subscription.provider_subscription_id,
          items: Enum.map(items, &%{id: subscription_item_id, price: &1, quantity: 1})
        },
        after_completion: %{
          type: :redirect,
          redirect: %{
            return_url: return_url(customer)
          }
        }
      }
    })
  end

  defp return_url(%Customer{} = customer) do
    case Customers.entity() do
      :user -> UrlHelpers.success_url(:user, customer.user_id, customer.id)
      :org -> UrlHelpers.success_url(:org, customer.org_id, customer.id)
    end <> "&switch_plan=true"
  end

  defp get_subscription_item(stripe_subscription) do
    stripe_subscription.items.data
    |> List.first()
    |> Map.get(:id)
  end
end
