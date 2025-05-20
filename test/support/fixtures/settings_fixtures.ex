defmodule PetalPro.SettingsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `PetalPro.Settings` context.
  """

  @doc """
  Generate a setting.
  """
  def setting_fixture(attrs \\ %{}) do
    {:ok, setting} =
      attrs
      |> Enum.into(%{
        value: %{"value" => "some value"},
        description: "some description",
        key: "test_key_#{System.unique_integer([:positive])}",
        type: "string",
        is_public: true
      })
      |> PetalPro.Settings.create_setting()

    setting
  end
end
