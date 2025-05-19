defmodule PetalPro.Orgs.Domain do
  @moduledoc """
  Schema representing a custom domain for an org.

  Each org can have multiple domains, with one marked as primary.
  This enables complete white-labeling capabilities while maintaining
  a clean separation of concerns between orgs.

  The domain verification system allows for secure domain ownership validation
  through DNS TXT records.
  """
  use PetalPro.Schema

  import Ecto.Changeset

  alias PetalPro.Orgs

  typed_schema "org_domains" do
    field :domain, :string
    field :is_primary, :boolean, default: false
    field :verified_at, :utc_datetime
    field :verification_code, :string

    # DNS configuration
    field :dns_configured, :boolean, default: false
    field :dns_checked_at, :utc_datetime

    # SSL configuration
    field :ssl_enabled, :boolean, default: false
    field :ssl_expires_at, :utc_datetime

    belongs_to :org, Orgs.Org

    timestamps()
  end

  @doc """
  Changeset for creating a new domain for an org.
  """
  def create_changeset(domain, attrs, parent_org \\ nil) do
    domain
    |> cast(attrs, [:domain, :is_primary, :org_id])
    |> validate_required([:domain, :org_id])
    |> validate_domain_format()
    |> validate_domain_hierarchy(parent_org)
    |> unique_constraint(:domain)
    |> generate_verification_code()
    |> foreign_key_constraint(:org_id)
  end

  @doc """
  Changeset for updating an existing domain.
  """
  def update_changeset(domain, attrs) do
    domain
    |> cast(attrs, [
      :is_primary,
      :verified_at,
      :dns_configured,
      :dns_checked_at,
      :ssl_enabled,
      :ssl_expires_at
    ])
    |> validate_primary_if_verified()
  end

  @doc """
  Special changeset for marking a domain as verified.
  """
  def verify_changeset(domain) do
    change(domain, %{verified_at: DateTime.utc_now()})
  end

  @doc """
  Special changeset for setting DNS configuration status.
  """
  def dns_check_changeset(domain, is_configured) do
    change(domain, %{dns_configured: is_configured, dns_checked_at: DateTime.utc_now()})
  end

  # Private validation functions

  defp validate_domain_format(changeset) do
    changeset
    |> validate_format(:domain, ~r/^(?:[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{2,}$/,
      message: "must be a valid domain name"
    )
    |> validate_exclusion(:domain, ["localhost"], message: "is reserved and cannot be used")
  end

  defp validate_primary_if_verified(changeset) do
    verified_at = get_field(changeset, :verified_at)
    is_primary = get_field(changeset, :is_primary)

    if is_primary && is_nil(verified_at) do
      add_error(changeset, :is_primary, "domain must be verified before it can be set as primary")
    else
      changeset
    end
  end

  defp generate_verification_code(changeset) do
    if get_field(changeset, :verification_code) == nil do
      verification_code = "petal-verify-" <> generate_random_string(32)
      put_change(changeset, :verification_code, verification_code)
    else
      changeset
    end
  end

  defp generate_random_string(length) do
    length
    |> :crypto.strong_rand_bytes()
    |> Base.url_encode64()
    |> String.slice(0, length)
  end

  @doc """
  Validates that a domain follows the hierarchical structure of orgs.
  For suborgs, the domain must be a subdomain of the parent tenant's domain.

  ## Options
    * parent_tenant - The parent tenant to validate the hierarchy against
  """
  def validate_domain_hierarchy(changeset, nil), do: changeset

  def validate_domain_hierarchy(changeset, parent_tenant) do
    domain = get_field(changeset, :domain)

    if domain && parent_tenant.primary_domain do
      parent_domain = parent_tenant.primary_domain

      if String.ends_with?(domain, ".#{parent_domain}") do
        changeset
      else
        add_error(changeset, :domain, "must be a subdomain of #{parent_domain}")
      end
    else
      changeset
    end
  end
end
