defmodule PetalPro.Billing.Providers.Behaviour do
  @moduledoc """
  To be implemented by all billing providers.
  """

  alias PetalPro.Accounts.User
  alias PetalPro.Billing.Customers.Customer
  alias PetalPro.Billing.Subscriptions.Subscription

  @type id :: String.t()
  @type user :: User.t()
  @type customer :: Customer.t()
  @type plan :: map()
  @type subscription :: Subscription.t()
  @type source :: :user | :org
  @type source_id :: String.t()
  @type session :: term()

  @callback checkout(user, plan, source, source_id) :: {:ok, session} | {:error, term()}
  @callback change_plan(customer, subscription, plan) :: {:ok, session} | {:error, term()}
  @callback checkout_url(session) :: String.t()
  @callback retrieve_product(id) :: {:ok, term()} | {:error, term()}
  @callback subscription_adapter() :: module()
  @callback get_subscription_product(term()) :: String.t()
  @callback get_subscription_price(term()) :: String.t() | number()
  @callback get_subscription_cycle(term()) :: String.t()
  @callback get_subscription_next_charge(term()) :: String.t() | Calendar.calendar()
  @callback retrieve_subscription(id) :: {:ok, term()} | {:error, term()}
  @callback cancel_subscription(id) :: {:ok, term()} | {:error, term()}
  @callback sync_subscription(customer) :: :ok

  defmacro __using__(_) do
    quote do
      @behaviour PetalPro.Billing.Providers.Behaviour

      import PetalPro.Billing.Providers.Behaviour.UrlHelpers
    end
  end

  defmodule UrlHelpers do
    @moduledoc false
    use PetalProWeb, :controller

    def success_url(:user, _user_id, customer_id) do
      url(PetalProWeb.Endpoint, ~p"/app/subscribe/success?customer_id=#{customer_id}")
    end

    def success_url(:org, org_id, customer_id) do
      org = PetalPro.Orgs.get_org_by_id(org_id)

      url(
        PetalProWeb.Endpoint,
        ~p"/app/org/#{org.slug}/subscribe/success?customer_id=#{customer_id}"
      )
    end

    def cancel_url(:user, _user_id), do: url(PetalProWeb.Endpoint, ~p"/app/subscribe")

    def cancel_url(:org, org_id) do
      org = PetalPro.Orgs.get_org_by_id(org_id)

      url(PetalProWeb.Endpoint, ~p"/app/org/#{org.slug}/subscribe")
    end
  end
end
