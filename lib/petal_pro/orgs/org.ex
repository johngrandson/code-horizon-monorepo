defmodule PetalPro.Orgs.Org do
  @moduledoc false
  use PetalPro.Schema

  alias PetalPro.Accounts.User
  alias PetalPro.Billing.Customers.Customer
  alias PetalPro.Extensions.Ecto.ChangesetExt
  alias PetalPro.Licenses.License
  alias PetalPro.Modules.Subscription
  alias PetalPro.Orgs.Domain
  alias PetalPro.Orgs.Invitation
  alias PetalPro.Orgs.Membership
  alias PetalPro.Repo
  alias PetalPro.WhiteLabel.Theme

  @derive {Phoenix.Param, key: :slug}
  typed_schema "orgs" do
    field :name, :string
    field :slug, :string
    field :schema_prefix, :string

    # Primary domain for this tenant (cached for performance)
    field :primary_domain, :string

    # Plan and billing information
    field :plan, Ecto.Enum, values: [:free, :starter, :professional, :enterprise], default: :free
    field :max_users, :integer, default: 5

    # Status fields
    field :status, Ecto.Enum, values: [:active, :suspended, :pending], default: :pending
    field :suspended_reason, :string

    # Additional metadata as JSON
    field :settings, :map, default: %{}

    # Associations
    belongs_to :theme, Theme

    has_one :customer, Customer

    has_many :memberships, Membership
    has_many :invitations, Invitation
    has_many :domains, Domain
    has_many :module_subscriptions, Subscription
    has_many :licenses, License

    many_to_many :users, User, join_through: "orgs_memberships", unique: true

    timestamps()
  end

  @doc """
  Changeset for inserting a new org.
  """
  def insert_changeset(attrs) do
    %__MODULE__{}
    |> cast(attrs, [:name, :plan, :max_users, :theme_id, :settings, :primary_domain])
    |> validate_name()
    |> generate_slug()
    |> generate_schema_prefix()
    |> unique_constraint(:slug)
    |> unique_constraint(:schema_prefix)
    |> unsafe_validate_unique(:slug, Repo)
  end

  @doc """
  Changeset for updating an existing org.
  """
  def update_changeset(org, attrs) do
    org
    |> cast(attrs, [
      :name,
      :primary_domain,
      :plan,
      :max_users,
      :status,
      :suspended_reason,
      :theme_id,
      :settings
    ])
    |> validate_name()
    |> validate_inclusion(:status, [:active, :suspended, :pending])
    |> validate_suspension_reason()
  end

  def validate_name(changeset) do
    changeset
    |> ChangesetExt.ensure_trimmed(:name)
    |> validate_required([:name])
    |> validate_length(:name, min: 2, max: 160)
  end

  # Generates a unique slug based on the tenant name
  defp generate_slug(changeset) do
    case get_change(changeset, :name) do
      nil ->
        changeset

      name ->
        slug =
          name
          |> String.downcase()
          |> String.replace(~r/[^a-z0-9\s-]/, "")
          |> String.replace(~r/\s+/, "-")

        # Add uniqueness suffix if needed
        timestamp = System.system_time(:second)
        unique_slug = "#{slug}-#{timestamp}"

        put_change(changeset, :slug, unique_slug)
    end
  end

  # Generates a PostgreSQL schema prefix for this tenant
  defp generate_schema_prefix(changeset) do
    case get_change(changeset, :slug) do
      slug when not is_nil(slug) ->
        # Create a safe schema name that includes org_id for PostgreSQL (max 63 chars)
        schema_prefix = String.slice("org_#{slug}", 0, 60)
        put_change(changeset, :schema_prefix, schema_prefix)

      _ ->
        changeset
    end
  end

  # Validate that suspension reason is provided when status is suspended
  defp validate_suspension_reason(changeset) do
    status = get_field(changeset, :status)
    reason = get_field(changeset, :suspended_reason)

    if status == :suspended && (is_nil(reason) || String.trim(reason) == "") do
      add_error(changeset, :suspended_reason, "must be provided when tenant is suspended")
    else
      changeset
    end
  end
end
