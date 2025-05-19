defmodule PetalPro.Accounts.UserSeeder do
  @moduledoc """
  Generates dummy users for the development environment.
  """
  alias PetalPro.Accounts
  alias PetalPro.Accounts.User
  alias PetalPro.Repo

  @password "password"

  def normal_user(attrs \\ %{}) do
    {:ok, user} = Accounts.register_user(attrs)
    {:ok, user} = Accounts.update_user_as_admin(user, attrs)
    user
  end

  def admin(attrs \\ %{}) do
    %{
      name: "John Smith",
      email: "admin@example.com",
      password: @password,
      confirmed_at: Timex.to_naive_datetime(DateTime.utc_now()),
      is_onboarded: true,
      role: :admin
    }
    |> Map.merge(attrs)
    |> normal_user()
  end

  def random_user(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> random_user_attributes()
      |> Accounts.register_user()

    user
  end

  # Use this for quickly inserting large numbers of users
  # We use insert_all to avoid hashing passwords one by one, which is slow
  def random_users(count) do
    now =
      DateTime.utc_now()
      |> Timex.to_naive_datetime()
      |> NaiveDateTime.truncate(:second)

    # This is for the password "password"
    password_hashed = "$2b$12$RCMCDT1LBBp1q7yGGqwkhuw9OgEFXOJEViSkXtC9VfRmivUh.Gk4a"

    users_data =
      Enum.map(1..count, fn _ ->
        random_user_attributes()
        |> Map.drop([:password])
        |> Map.merge(%{
          inserted_at: now,
          updated_at: now,
          confirmed_at: Enum.random([now, now, now, nil]),
          hashed_password: password_hashed
        })
      end)

    Repo.insert_all(User, users_data)
  end

  # Creates a fake subscription
  def fake_subscription(%Accounts.User{} = user) do
    now = DateTime.utc_now() |> Timex.to_naive_datetime() |> NaiveDateTime.truncate(:second)

    {:ok, customer} =
      PetalPro.Billing.Customers.create_customer_for_source(:user, user.id, %{
        email: user.email,
        provider: "stripe",
        provider_customer_id: "cus_123"
      })

    PetalPro.Billing.Subscriptions.create_subscription!(%{
      status: "active",
      plan_id: "plan_123",
      provider_subscription_id: "sub_123",
      provider_subscription_items: [],
      cancel_at: nil,
      canceled_at: nil,
      current_period_end_at: Timex.shift(now, days: 30),
      current_period_start: Timex.shift(now, days: -30),
      billing_customer_id: customer.id
    })
  end

  def unique_user_email, do: "user#{System.unique_integer()}@example.com"

  def random_user_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      name: Faker.Person.En.first_name() <> " " <> Faker.Person.En.last_name(),
      email: unique_user_email(),
      password: "password"
    })
  end
end
