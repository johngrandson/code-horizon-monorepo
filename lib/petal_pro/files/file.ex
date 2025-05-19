defmodule PetalPro.Files.File do
  @moduledoc false
  use Ecto.Schema

  import Ecto.Changeset

  schema "files" do
    field :url, :string
    field :name, :string

    field :archived, :boolean, default: false

    belongs_to :author, PetalPro.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(file, attrs) do
    file
    |> cast(attrs, [:url, :name, :archived])
    |> validate_required([:url, :name, :archived])
  end
end
