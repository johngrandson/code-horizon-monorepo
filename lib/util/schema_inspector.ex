defmodule SchemaInspector do
  @moduledoc false
  def inspect_schema(module) do
    %{
      source: module,
      fields:
        module.__struct__()
        |> Map.from_struct()
        |> Map.delete(:__meta__)
        |> Enum.map(fn {fieldname, _default} ->
          %{name: fieldname, type: fieldtype(module, fieldname)}
        end)
    }
  end

  defp fieldtype(module, fieldname) do
    module.__changeset__()
    |> Map.get(fieldname)
    |> case do
      {:embed, %Ecto.Embedded{cardinality: :many, related: related}} -> "ARRAY(#{related})"
      other -> other
    end
  end
end
