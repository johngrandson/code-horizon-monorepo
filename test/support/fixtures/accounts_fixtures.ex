defmodule PetalPro.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `PetalPro.Accounts` context.
  """
  alias PetalPro.Accounts
  alias PetalPro.Accounts.User
  alias PetalPro.Repo

  @totp_secret Base.decode32!("PTEPUGZ7DUWTBGMW4WLKB6U63MGKKMCA")

  def valid_totp_secret, do: @totp_secret
  def unique_user_email, do: "user#{System.unique_integer()}@example.com"
  def valid_user_password, do: "password"

  def valid_user_attributes(attrs \\ %{}) do
    # Faker sometimes produces a name like O'Brian. This may cause a test to fail when checking for a name as it renders in the HTML as O&#39;Brian
    random_name = String.replace(Faker.Person.name(), "'", "")

    Enum.into(attrs, %{
      name: random_name,
      email: unique_user_email(),
      password: valid_user_password()
    })
  end

  def confirmed_user_fixture(attrs \\ %{}) do
    attrs
    |> user_fixture()
    |> Accounts.confirm_user!()
  end

  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> valid_user_attributes()
      |> Accounts.register_user()

    {:ok, user} = Accounts.update_user_as_admin(user, attrs)

    user
  end

  def admin_fixture(attrs \\ %{}) do
    user =
      attrs
      |> Map.put(:role, :admin)
      |> user_fixture()

    {:ok, user} =
      user
      |> User.confirm_changeset()
      |> Repo.update()

    user
  end

  def impersonator_fixture(attrs \\ %{}) do
    admin_user = admin_fixture()

    user =
      attrs
      |> user_fixture()
      |> Map.put(:current_impersonator, admin_user)

    {:ok, user} =
      user
      |> User.confirm_changeset()
      |> Repo.update()

    %{user: user, admin_user: admin_user}
  end

  def user_totp_fixture(user) do
    %Accounts.UserTOTP{}
    |> Ecto.Changeset.change(user_id: user.id, secret: valid_totp_secret())
    |> Accounts.UserTOTP.ensure_backup_codes()
    |> Repo.insert!()
  end

  def extract_user_token(fun) do
    {:ok, captured_email} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token | _] = String.split(captured_email.text_body, "[TOKEN]")
    token
  end
end
