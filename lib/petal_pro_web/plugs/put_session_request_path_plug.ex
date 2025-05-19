defmodule PetalProWeb.PutSessionRequestPathPlug do
  @moduledoc """
  Makes the conn `:request_path` available in the session.
  """
  use Phoenix.Controller

  import Plug.Conn

  def call(%{request_path: request_path} = conn, _) when is_binary(request_path) do
    put_session(conn, :request_path, request_path)
  end

  def call(conn, _), do: conn
end
