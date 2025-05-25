defmodule PetalPro.AppModulesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `PetalPro.AppModules` context.
  """

  @doc """
  Generate a unique module code.
  """
  def unique_module_code, do: "some code#{System.unique_integer([:positive])}"

  @doc """
  Generate a module.
  """
  def module_fixture(attrs \\ %{}) do
    {:ok, module} =
      attrs
      |> Enum.into(%{
        cleanup_function: "some cleanup_function",
        code: unique_module_code(),
        dependencies: "some dependencies",
        description: "some description",
        is_publicly_visible: true,
        is_white_label_ready: true,
        name: "some name",
        price_id: "some price_id",
        routes_definition: "some routes_definition",
        setup_function: "some setup_function",
        status: "some status",
        version: "some version"
      })
      |> PetalPro.AppModules.create_app_module()

    module
  end
end
