defmodule PetalPro.Billing.Customers.Customer do
  @moduledoc """
  A customer is something that has a subscription to a product. It can be attached to either a user or org.

  You can choose which one to associate it with. It's usually better to attach it to an org, so if a user leaves the org, the subscription can continue.

  However, if you know you'll never have more than one user per account/org, you can attach it to a user.
  """

  use PetalPro.Schema

  typed_schema "billing_customers" do
    field :email, :string
    field :provider, :string
    field :provider_customer_id, :string

    belongs_to :user, PetalPro.Accounts.User
    belongs_to :org, PetalPro.Orgs.Org

    has_many :subscriptions, PetalPro.Billing.Subscriptions.Subscription, foreign_key: :billing_customer_id

    timestamps()
  end

  def changeset_by_source(customer, source, attrs) do
    # e.g. if source is "user", then we need to make sure that the user_id is set
    source_id_field = source_id_field(source)

    cast_attrs = [:email, :provider, :provider_customer_id, source_id_field]
    required_attrs = [:email, :provider, :provider_customer_id, source_id_field]

    customer
    |> cast(attrs, cast_attrs)
    |> validate_required(required_attrs)
  end

  def source_id_field(:user), do: :user_id
  def source_id_field(:org), do: :org_id
end
