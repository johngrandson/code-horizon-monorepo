defmodule PetalProWeb.Presence do
  @moduledoc false
  use Phoenix.Presence, otp_app: :petal_pro, pubsub_server: PetalPro.PubSub

  alias PetalPro.Accounts

  def online_user?(%Accounts.User{} = user) do
    online = not ("users" |> get_by_key(user.id) |> Enum.empty?())
    %{user | is_online: online}
  end

  def online_users(users) when is_list(users) do
    Enum.map(users, &online_user?/1)
  end
end
