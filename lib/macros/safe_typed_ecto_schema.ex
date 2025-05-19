defmodule PetalPro.Macros.SafeTypedEctoSchema do
  @moduledoc """
  A macro to use `TypedEctoSchema` only when it's installed, otherwise fallback to `Ecto.Schema`.
  """
  defmacro __using__(_) do
    case Code.ensure_compiled(TypedEctoSchema) do
      {:module, _} ->
        quote do
          use TypedEctoSchema
        end

      {:error, _} ->
        quote do
          use Ecto.Schema

          import PetalPro.Macros.SafeTypedEctoSchema,
            only: [
              typed_schema: 2
            ]
        end
    end
  end

  @doc """
  Replaces `TypedEctoSchema.typed_schema/2` with `Ecto.Schema.schema/2` when the former is absent`
  """
  defmacro typed_schema(table_name, do: block) do
    quote do
      Ecto.Schema.schema unquote(table_name) do
        unquote(block)
      end
    end
  end
end
