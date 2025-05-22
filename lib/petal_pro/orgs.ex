defmodule PetalPro.Orgs do
  @moduledoc false
  use PetalProWeb, :verified_routes

  import Ecto.Query, only: [from: 2]

  alias PetalPro.Events.Modules.Orgs.Broadcaster
  alias PetalPro.Notifications
  alias PetalPro.Notifications.UserMailer
  alias PetalPro.Notifications.UserNotification
  alias PetalPro.Notifications.UserNotificationAttrs
  alias PetalPro.Orgs.Invitation
  alias PetalPro.Orgs.Membership
  alias PetalPro.Orgs.Org
  alias PetalPro.Repo

  @membership_roles ~w(member admin)

  ## Orgs

  def list_orgs(user) do
    Repo.preload(user, :orgs).orgs
  end

  def list_orgs do
    Repo.all(from(o in Org, order_by: :id))
  end

  def get_org!(user, slug) when is_binary(slug) do
    user
    |> Ecto.assoc(:orgs)
    |> Repo.get_by!(slug: slug)
  end

  def get_org!(slug) when is_binary(slug) do
    Repo.get_by!(Org, slug: slug)
  end

  def get_org_by_id(id) do
    Repo.get(Org, id)
  end

  def get_org_by_id!(id) do
    Repo.get!(Org, id)
  end

  def preload_org_memberships(org) do
    Repo.preload(org, memberships: :user)
  end

  def list_org_admin_users(%Org{} = org) do
    Repo.all(
      from(m in Membership,
        join: u in assoc(m, :user),
        where: m.org_id == ^org.id and m.role == :admin,
        select: %{user_id: u.id, user: u}
      )
    )
  end

  def create_org(attrs) do
    attrs
    |> Org.insert_changeset()
    |> Repo.insert()
  end

  def create_org(user, attrs) do
    unless user.confirmed_at do
      raise ArgumentError, "user must be confirmed to create an org"
    end

    changeset = Org.insert_changeset(attrs)

    multi =
      Ecto.Multi.new()
      |> Ecto.Multi.insert(:org, changeset)
      |> Ecto.Multi.insert(:membership, fn %{org: org} ->
        Membership.insert_changeset(org, user, :admin)
      end)

    case Repo.transaction(multi) do
      {:ok, %{org: org}} ->
        PetalProWeb.AdminDashboardLive.notify_admin_stats()
        {:ok, org}

      {:error, :org, changeset, _} ->
        {:error, changeset}
    end
  end

  def update_org(%Org{} = org, attrs) do
    org
    |> Org.update_changeset(attrs)
    |> Repo.update()
  end

  def delete_org(%Org{} = org) do
    Repo.delete(org)
  end

  def change_org(org, attrs \\ %{}) do
    if Ecto.get_meta(org, :state) == :loaded do
      Org.update_changeset(org, attrs)
    else
      Org.insert_changeset(attrs)
    end
  end

  @doc """
  This will find any invitations for a user's email address and assign them to the user.
  It will also delete any invitations to orgs the user is already a member of.
  Run this after a user has confirmed or changed their email.
  """
  def sync_user_invitations(user) do
    Ecto.Multi.new()
    |> Ecto.Multi.update_all(:updated_invitations, Invitation.assign_to_user_by_email(user), [])
    |> Ecto.Multi.delete_all(:deleted_invitations, Invitation.get_stale_by_user_id(user.id))
    |> Repo.transaction()
  end

  ## Members

  def list_members_by_org(org) do
    Repo.preload(org, :users).users
  end

  def create_membership(org, user, role) do
    org
    |> Membership.insert_changeset(user, role)
    |> Repo.insert()
  end

  def delete_membership(membership) do
    Repo.delete(Membership.delete_changeset(membership))
  end

  def get_membership!(user, org_slug) when is_binary(org_slug) do
    user
    |> Membership.by_user_and_org_slug(org_slug)
    |> Repo.one!()
    |> Repo.preload(:org)
  end

  def get_membership!(id) do
    Membership
    |> Repo.get!(id)
    |> Repo.preload([:user])
  end

  def membership_roles do
    @membership_roles
  end

  def change_membership(%Membership{} = membership, attrs \\ %{}) do
    Membership.update_changeset(membership, attrs)
  end

  def update_membership(%Membership{} = membership, attrs) do
    membership
    |> Membership.update_changeset(attrs)
    |> Repo.update()
  end

  ## Invitations - org based

  def get_invitation_by_org!(org, id) do
    org
    |> Invitation.by_org()
    |> Repo.get!(id)
  end

  def delete_invitation(invitation) do
    Repo.delete(invitation)
  end

  def delete_invitation_multi(multi, invitation) do
    Ecto.Multi.delete(multi, :invitation, invitation)
  end

  def build_invitation(%Org{} = org, params) do
    Invitation.changeset(%Invitation{org_id: org.id}, params)
  end

  def create_invitation(org, params) do
    %Invitation{org_id: org.id}
    |> Invitation.changeset(params)
    |> Repo.insert()
  end

  def create_invitation_multi(%Ecto.Multi{} = multi, org, invite_params) do
    invitation_cs = Invitation.changeset(%Invitation{org_id: org.id}, invite_params)
    Ecto.Multi.insert(multi, :invitation, invitation_cs)
  end

  # the notification concerns an existing user in our db, create a user_notification
  defp maybe_create_user_notification_multi(multi, notification_attrs, recipient_user_id)
       when not is_nil(recipient_user_id) do
    Notifications.create_user_notification_multi(multi, notification_attrs)
  end

  # no recipient was specified, so don't create a user notification (e.g. cases where only email notification possible)
  defp maybe_create_user_notification_multi(multi, _attrs, _user_id) do
    multi
  end

  defp maybe_delete_user_notification_multi(multi, %Invitation{user_id: nil}), do: multi

  defp maybe_delete_user_notification_multi(multi, invitation) do
    notifications_sent_query =
      from(un in UserNotification,
        where: un.type == :invited_to_org and un.recipient_id == ^invitation.user_id and un.org_id == ^invitation.org_id
      )

    Ecto.Multi.delete_all(multi, :delete_sent_notifications, notifications_sent_query)
  end

  @doc """
  Send an org invitation to the intended recipient:

      1. Creates the invitation
      2. If recipient is an existing user, creates and broadcasts user notification
      3. Delivers the invite email to the recipient
  """
  def send_org_invitation(org, org_admin, invite_params) do
    sender_id = org_admin.id

    invitation_cs =
      Invitation.changeset(%Invitation{org_id: org.id}, invite_params)

    recipient_id = Ecto.Changeset.get_field(invitation_cs, :user_id)
    user_notification_attrs = UserNotificationAttrs.invite_to_org_notification(org, sender_id, recipient_id)

    Ecto.Multi.new()
    |> create_invitation_multi(org, invite_params)
    |> maybe_create_user_notification_multi(user_notification_attrs, recipient_id)
    |> Repo.transaction()
    |> case do
      {:ok, %{invitation: invitation} = txn_result} ->
        if invitation.user_id do
          Notifications.broadcast_user_notification(txn_result.user_notification)

          Broadcaster.broadcast_invitation_sent(invitation, org)

          Broadcaster.broadcast_to_org_admins(org, :invitation_sent, %{invitation_id: invitation.id})
        end

        to = if(invitation.user_id, do: url(~p"/app/users/org-invitations"), else: url(~p"/auth/register"))
        UserMailer.deliver_org_invitation(org, invitation, to)

        {:ok, txn_result}

      {:error, :invitation, error, _} ->
        {:error, error}

      {:error, error} ->
        {:error, error}
    end
  end

  @doc """
  Rescind an invite to an organization. Deletes the invitation and any associated user notification.
  """
  def rescind_and_delete_org_invitation(invitation) do
    Ecto.Multi.new()
    |> delete_invitation_multi(invitation)
    |> maybe_delete_user_notification_multi(invitation)
    |> Repo.transaction()
    |> case do
      {:ok, %{invitation: invitation} = txn_result} ->
        {deleted_count, _} = Map.get(txn_result, :delete_sent_notifications, {0, nil})

        if deleted_count > 0 do
          Notifications.broadcast_user_notification(invitation.user_id)

          Broadcaster.broadcast_invitation_deleted(invitation)
        end

        {:ok, txn_result}

      {:error, error} ->
        {:error, error}
    end
  end

  ## Invitations - user based

  def list_invitations_by_user(user) do
    user
    |> Invitation.by_user()
    |> Repo.all()
    |> Repo.preload(:org)
  end

  def accept_invitation!(user, id) do
    invitation = get_invitation_by_user!(user, id)
    org = Repo.one!(Ecto.assoc(invitation, :org))

    Ecto.Multi.new()
    |> Ecto.Multi.insert(:membership, Membership.insert_changeset(org, user))
    |> Ecto.Multi.delete(:invitation, invitation)
    |> Repo.transaction()
    |> case do
      {:ok, %{membership: membership}} ->
        Broadcaster.broadcast_invitation_accepted(invitation, org)
        %{membership | org: org}

      {:error, error} ->
        {:error, error}
    end
  end

  def reject_invitation(user, id) do
    invitation =
      user
      |> get_invitation_by_user!(id)
      |> Repo.preload(:org)

    case Repo.delete(invitation) do
      {:ok, _} ->
        Notifications.broadcast_user_notification(invitation.user_id)

        Broadcaster.broadcast_invitation_rejected(invitation, invitation.org)
        {:ok, invitation}

      error ->
        error
    end
  end

  def reject_invitation!(user, id) do
    case reject_invitation(user, id) do
      {:ok, invitation} ->
        invitation

      {:error, changeset} ->
        raise Ecto.InvalidChangesetError, action: :delete, changeset: changeset
    end
  end

  defp get_invitation_by_user!(user, id) do
    user
    |> Invitation.by_user()
    |> Repo.get!(id)
    |> Repo.preload(:org)
  end
end
