defmodule PetalPro.AppModules.Subscription do
  @moduledoc """
  Schema representing a tenant's subscription to a module.
  """
  use PetalPro.Schema

  alias PetalPro.Orgs.Org

  typed_schema "app_module_subscriptions" do
    field :module_code, :string
    field :active, :boolean, default: false
    field :expires_at, :utc_datetime

    belongs_to :org, Org

    timestamps()
  end

  def changeset(subscription, attrs) do
    subscription
    |> cast(attrs, [:module_code, :org_id, :active, :expires_at])
    |> validate_required([:module_code, :org_id, :active])
    |> unique_constraint([:org_id, :module_code])
  end
end
