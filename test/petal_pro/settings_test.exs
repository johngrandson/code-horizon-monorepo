defmodule PetalPro.SettingsTest do
  use PetalPro.DataCase

  alias PetalPro.Settings

  describe "settings" do
    alias PetalPro.Settings.Setting

    import PetalPro.SettingsFixtures

    @invalid_attrs %{value: nil, description: nil, key: nil}

    test "list_settings/0 returns all settings" do
      setting = setting_fixture()
      assert Settings.list_settings() == [setting]
    end

    test "get_setting!/1 returns the setting with given id" do
      setting = setting_fixture()
      assert Settings.get_setting!(setting.id) == setting
    end

    test "create_setting/1 with valid data creates a setting" do
      valid_attrs = %{value: "some value", description: "some description", key: "some key"}

      assert {:ok, %Setting{} = setting} = Settings.create_setting(valid_attrs)
      assert setting.value == "some value"
      assert setting.description == "some description"
      assert setting.key == "some key"
    end

    test "create_setting/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Settings.create_setting(@invalid_attrs)
    end

    test "update_setting/2 with valid data updates the setting" do
      setting = setting_fixture()
      update_attrs = %{value: "some updated value", description: "some updated description", key: "some updated key"}

      assert {:ok, %Setting{} = setting} = Settings.update_setting(setting, update_attrs)
      assert setting.value == "some updated value"
      assert setting.description == "some updated description"
      assert setting.key == "some updated key"
    end

    test "update_setting/2 with invalid data returns error changeset" do
      setting = setting_fixture()
      assert {:error, %Ecto.Changeset{}} = Settings.update_setting(setting, @invalid_attrs)
      assert setting == Settings.get_setting!(setting.id)
    end

    test "delete_setting/1 deletes the setting" do
      setting = setting_fixture()
      assert {:ok, %Setting{}} = Settings.delete_setting(setting)
      assert_raise Ecto.NoResultsError, fn -> Settings.get_setting!(setting.id) end
    end

    test "change_setting/1 returns a setting changeset" do
      setting = setting_fixture()
      assert %Ecto.Changeset{} = Settings.change_setting(setting)
    end
  end
end
