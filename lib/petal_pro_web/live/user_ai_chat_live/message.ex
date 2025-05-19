defmodule PetalProWeb.UserAiChatLive.Message do
  @moduledoc false
  use Ecto.Schema

  import Ecto.Changeset

  embedded_schema do
    field :content, :string
  end

  def changeset(message \\ %__MODULE__{}, attrs \\ %{}) do
    message
    |> cast(attrs, [:content])
    |> validate_required([:content])
    |> validate_length(:content, min: 1)
  end
end
