defmodule PetalPro.Billing.Customers do
  @moduledoc false
  import Ecto.Query, warn: false

  alias PetalPro.Billing.Customers.Customer
  alias PetalPro.Billing.Customers.CustomerQuery
  alias PetalPro.Repo

  def entity do
    PetalPro.config(:billing_entity)
  end

  def get_customer_by(attrs) do
    Customer
    |> Repo.get_by(attrs)
    |> Repo.preload(:subscriptions)
  end

  def get_customer_by_provider_customer_id!(id) do
    Repo.get_by!(Customer, provider_customer_id: id)
  end

  def get_customer_by_source(source, source_id) do
    source
    |> CustomerQuery.by_source(source_id)
    |> Repo.one()
  end

  def create_customer_for_source(source, source_id, attrs \\ %{}) do
    attrs =
      case source do
        :user -> Map.put(attrs, :user_id, source_id)
        :org -> Map.put(attrs, :org_id, source_id)
      end

    create_customer_by_source(source, attrs)
  end

  def create_customer_by_source(source, attrs \\ %{}) do
    {
      :ok,
      %Customer{}
      |> Customer.changeset_by_source(source, attrs)
      |> Repo.insert!()
      |> Repo.preload([:user, :org])
    }
  end
end
