defmodule PetalProWeb.DataTable.DataTableCellTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias PetalProWeb.DataTable.Cell

  test "sanity check" do
    assert money(10) =~ "$10.00"
    assert money(10, "EUR") =~ "€10.00"
    assert money(10, :EUR) =~ "€10.00"

    assert money(10.3) =~ "$10.30"
    assert money("10.30") =~ "$10.30"

    assert date(~D[2023-08-20]) =~ "2023-08-20"
    assert date(~D[2023-08-20], "%y") =~ "23"

    assert datetime(~U[2023-08-20 18:31:30Z]) =~ "06:31PM 2023-08-20"
    assert datetime(~U[2023-08-20 18:31:30Z], "%Y-%m-%d %I:%M") =~ "2023-08-20 06:31"
  end

  defp money(price, currency \\ nil) do
    render_component(&Cell.render/1,
      item: %{price: price},
      column: %{renderer: :money, field: :price, currency: currency}
    )
  end

  defp date(date, format \\ nil) do
    render_component(&Cell.render/1,
      item: %{date: date},
      column: %{renderer: :date, field: :date, date_format: format}
    )
  end

  defp datetime(date, format \\ nil) do
    render_component(&Cell.render/1,
      item: %{date: date},
      column: %{renderer: :datetime, field: :date, date_format: format}
    )
  end
end
