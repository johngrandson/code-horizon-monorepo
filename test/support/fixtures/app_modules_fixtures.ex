defmodule PetalPro.AppModulesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `PetalPro.AppModules` context.
  """

  @doc """
  Generate a app_module.
  """
  def app_module_fixture(attrs \\ %{}) do
    {:ok, app_module} =
      attrs
      |> Enum.into(%{
        AppModules: "some AppModules"
      })
      |> PetalPro.AppModules.create_app_module()

    app_module
  end
end
