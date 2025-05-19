defmodule PetalProApi.SessionJSON do
  def create(%{token: token, token_type: token_type}) do
    %{
      token: token,
      token_type: token_type
    }
  end
end
