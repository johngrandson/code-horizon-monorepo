defmodule PetalPro.Billing.Providers.Stripe.Services.FindOrCreateCustomer do
  @moduledoc """
  This module provides a function to find or create a customer in Stripe and locally.
  """

  alias PetalPro.Billing.Customers
  alias PetalPro.Billing.Providers.Stripe.Provider

  def call(current_user, source, source_id) do
    case Customers.get_customer_by_source(source, source_id) do
      nil -> create_customer(current_user, source, source_id)
      customer -> {:ok, customer}
    end
  end

  defp create_customer(current_user, source, source_id) do
    case Provider.create_customer(%{
           email: current_user.email
         }) do
      {:ok, stripe_customer} ->
        Customers.create_customer_for_source(source, source_id, %{
          email: current_user.email,
          provider: "stripe",
          provider_customer_id: stripe_customer.id
        })

      {:error, error} ->
        raise "Failed to create Stripe Customer: #{inspect(error)}"
    end
  end
end
