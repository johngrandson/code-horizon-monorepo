defmodule PetalProWeb.UserSocket do
  @moduledoc """
  A general-purpose socket for user-specific channels.
  """
  use Phoenix.Socket

  alias PetalPro.Accounts.User

  ## Channels

  channel "user_notifications:*", PetalProWeb.UserNotificationsChannel

  @impl true
  def connect(%{"token" => token}, socket, _connect_info) do
    # max_age: 1209600 is equivalent to two weeks in seconds
    case Phoenix.Token.verify(socket, "user socket", token, max_age: 1_209_600) do
      {:ok, user_id} ->
        {:ok, assign(socket, :user_id, Integer.to_string(user_id))}

      {:error, _reason} ->
        :error
    end
  end

  @impl true
  def id(%{assigns: %{current_user: %User{id: user_id}}}) when not is_nil(user_id), do: "user_socket:#{user_id}"

  def id(%{user_id: user_id}) when not is_nil(user_id), do: "user_socket:#{user_id}"
  def id(_socket), do: nil
end
