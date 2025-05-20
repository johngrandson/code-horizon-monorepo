defmodule PetalPro.SettingsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `PetalPro.Settings` context.
  """

  @doc """
  Generate a setting.
  """
  def setting_fixture(attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        description: "some description",
        key: "some key",
        value: %{"value" => "some value"}
      })

    {:ok, setting} = PetalPro.Settings.create_setting(attrs)
    setting
  end
end
