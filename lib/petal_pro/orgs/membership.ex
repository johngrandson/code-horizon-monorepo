defmodule PetalPro.Orgs.Membership do
  @moduledoc false
  use PetalPro.Schema
  use Gettext, backend: PetalProWeb.Gettext

  import Ecto.Query

  alias PetalPro.Accounts.User
  alias PetalPro.Orgs.Org
  alias PetalPro.Repo

  @role_options ~w(admin member)a
  @default_role :member
  @admin_role :admin

  typed_schema "orgs_memberships" do
    field :role, Ecto.Enum, values: @role_options

    belongs_to :user, User
    belongs_to :org, Org

    timestamps()
  end

  def by_user_and_org_slug(%User{} = user, org_slug) do
    from(ms in __MODULE__,
      join: org in assoc(ms, :org),
      on: [slug: ^org_slug],
      where: ms.user_id == ^user.id
    )
  end

  def list_orgs_by_user(%User{} = user) do
    user
    |> list_orgs_by_user_query()
    |> Repo.all()
  end

  def list_orgs_by_user_query(%User{} = user) do
    from(ms in __MODULE__,
      join: org in assoc(ms, :org),
      where: ms.user_id == ^user.id,
      select: org
    )
  end

  def is_org_admin?(%User{} = user) do
    Repo.exists?(from(ms in __MODULE__, where: ms.user_id == ^user.id and ms.role == @admin_role))
  end

  def current_user_role_in_org(%User{} = user, %Org{} = org) do
    Repo.one(from(ms in __MODULE__, where: ms.user_id == ^user.id and ms.org_id == ^org.id, select: ms.role))
  end

  def list_orgs(%User{} = user) do
    Repo.all(
      from(o in Org,
        join: m in __MODULE__,
        on: m.org_id == o.id,
        where: m.user_id == ^user.id,
        select: o
      )
    )
  end

  def all_by_org(%Org{} = org) do
    from(m in __MODULE__,
      join: u in assoc(m, :user),
      join: o in assoc(m, :org),
      on: o.id == ^org.id,
      preload: [:user]
    )
  end

  def org_members_count(%Org{} = org) do
    Repo.count(from(m in __MODULE__, where: m.org_id == ^org.id))
  end

  def pending_invitations_count(%Org{} = org) do
    Repo.count(from(m in __MODULE__, where: m.org_id == ^org.id and is_nil(m.user_id)))
  end

  def insert_changeset(org, user, role \\ @default_role) do
    %__MODULE__{
      org_id: org.id,
      user_id: user.id,
      role: role
    }
    |> change()
    |> unique_constraint([:org_id, :user_id])
    |> validate_inclusion(:role, @role_options)
  end

  def update_changeset(membership, attrs) do
    membership
    |> cast(attrs, [:role])
    |> validate_required([:role])
    |> prepare_changes(fn changeset ->
      current_role = membership.role
      new_role = get_change(changeset, :role)

      if current_role == @admin_role && new_role != current_role do
        validate_at_least_one_admin(changeset)
      else
        changeset
      end
    end)
  end

  def delete_changeset(%__MODULE__{} = membership) do
    membership
    |> change()
    |> prepare_changes(&validate_at_least_one_admin/1)
  end

  defp validate_at_least_one_admin(changeset) do
    org_id = changeset.data.org_id
    user_id = changeset.data.user_id

    query =
      from(m in __MODULE__,
        where: m.org_id == ^org_id and m.role == @admin_role and m.user_id != ^user_id,
        select: count(1)
      )

    if changeset.repo.one!(query) > 0 do
      changeset
    else
      add_error(changeset, :role, gettext("cannot remove last admin of the organization"))
    end
  end
end
