defmodule PetalPro.Accounts.UserPinTest do
  use PetalPro.DataCase

  import PetalPro.AccountsFixtures

  alias PetalPro.Accounts.UserPin

  @allowed_attempts 1
  @wrong_pin "xxxxxx"

  setup do
    user = user_fixture()
    pin = UserPin.create_pin(user)

    other_user = user_fixture()
    UserPin.create_pin(other_user)

    {:ok, user: user, pin: pin, other_user: other_user}
  end

  describe "pin validation" do
    test "got it first try", %{user: user, pin: pin} do
      assert {:ok, _user_pin} = UserPin.validate_pin(user, pin, @allowed_attempts)
    end

    test "wrong pin", %{user: user} do
      assert {:error, :incorrect_pin} = UserPin.validate_pin(user, @wrong_pin, @allowed_attempts)
    end

    test "retry fails", %{user: user, pin: pin} do
      UserPin.failed_attempt(user)

      assert {:error, :too_many_incorrect_attempts} =
               UserPin.validate_pin(user, pin, @allowed_attempts)
    end

    test "pin has expired", %{user: user, pin: pin} do
      expire_pin(user)
      assert {:error, :expired} = UserPin.validate_pin(user, pin, @allowed_attempts)
    end

    test "pin does not exist", %{pin: pin} do
      oblivious_user = user_fixture()
      assert {:error, :not_found} = UserPin.validate_pin(oblivious_user, pin, @allowed_attempts)
    end
  end

  describe "pin existence" do
    test "pin exists", %{user: user} do
      assert UserPin.valid_pin_exists?(user)
    end

    test "purged pin does not exist", %{user: user} do
      UserPin.purge_pins(user)
      refute UserPin.valid_pin_exists?(user)
    end

    test "purged pin does not affect other pin", %{user: user, other_user: other_user} do
      UserPin.purge_pins(user)
      assert UserPin.valid_pin_exists?(other_user)
    end

    test "purge affects nominated user and users with expired pins", %{
      user: user,
      other_user: other_user
    } do
      expire_pin(other_user)
      UserPin.purge_pins(user)

      refute UserPin.valid_pin_exists?(user)
      refute UserPin.valid_pin_exists?(other_user)
    end
  end

  defp expire_pin(user) do
    minutes_ago =
      NaiveDateTime.add(NaiveDateTime.utc_now(), -UserPin.pin_validity_in_minutes(), :minute)

    Repo.update_all(
      from(u in UserPin, where: u.user_id == ^user.id, update: [set: [inserted_at: ^minutes_ago]]),
      []
    )
  end
end
