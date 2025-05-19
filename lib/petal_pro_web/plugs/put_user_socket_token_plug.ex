defmodule PetalProWeb.PutUserSocketTokenPlug do
  @moduledoc """
  For clients to connect to the user notifications channel, they've first got to authenticate with
  the user socket. This plug puts `:user_socket_token` in assigns, to be initialised in a JS script tag.
  """
  use Phoenix.Controller

  import Plug.Conn

  alias PetalPro.Accounts.User

  def call(%{assigns: %{current_user: %User{} = current_user}} = conn, _) do
    token = Phoenix.Token.sign(conn, "user socket", current_user.id)
    assign(conn, :user_socket_token, token)
  end

  def call(conn, _), do: conn
end
