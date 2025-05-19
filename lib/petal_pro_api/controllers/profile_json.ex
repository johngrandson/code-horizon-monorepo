defmodule PetalProApi.ProfileJSON do
  @doc """
  Renders a single user.
  """
  def show(%{user: user}) do
    %{
      id: user.id,
      name: user.name,
      email: user.email,
      is_confirmed: user.confirmed_at != nil,
      is_admin: user.role == :admin,
      role: user.role,
      avatar: user.avatar,
      is_suspended: user.is_suspended,
      is_deleted: user.is_deleted,
      is_onboarded: user.is_onboarded
    }
  end
end
