defmodule PetalPro.OrgsFixtures do
  @moduledoc false
  alias PetalPro.Accounts.User
  alias PetalPro.AccountsFixtures
  alias PetalPro.Orgs
  alias PetalPro.Orgs.Membership

  def unique_org_name, do: "org#{System.unique_integer([:positive])}"
  def unique_invitation_email, do: "invitation#{System.unique_integer([:positive])}@example.com"

  def org_fixture do
    user = AccountsFixtures.confirmed_user_fixture()
    org_fixture(user, %{})
  end

  def org_fixture(%User{} = user, attrs \\ %{}) do
    name = unique_org_name()

    attrs =
      Enum.into(attrs, %{
        name: name,
        status: :active,
        plan: :free,
        max_users: 10,
        settings: %{},
        primary_domain: "#{String.downcase(name)}.example.com"
      })

    {:ok, org} = Orgs.create_org(user, attrs)
    org
  end

  def membership_fixture(org, user, role \\ :member) do
    PetalPro.Repo.insert!(Membership.insert_changeset(org, user, role))
  end

  def org_member_fixture(org, user_attrs \\ %{}) do
    user = AccountsFixtures.confirmed_user_fixture(user_attrs)
    membership_fixture(org, user)
    user
  end

  def org_admin_fixture(org, user_attrs \\ %{}) do
    user = AccountsFixtures.confirmed_user_fixture(user_attrs)
    membership_fixture(org, user, :admin)
    user
  end

  def invitation_fixture(org, attrs \\ %{}) do
    attrs = Map.put_new(attrs, :email, unique_invitation_email())
    {:ok, invitation} = Orgs.create_invitation(org, attrs)
    invitation
  end
end
