defmodule PetalPro.Schema do
  @moduledoc """
  Use this in every schema file.
  """
  defmacro __using__(_) do
    quote do
      use PetalPro.Macros.SafeTypedEctoSchema
      use QueryBuilder

      import Ecto.Changeset
    end
  end
end
