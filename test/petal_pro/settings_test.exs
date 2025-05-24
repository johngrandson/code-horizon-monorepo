defmodule PetalPro.SettingsTest do
  # use PetalPro.DataCase

  # alias PetalPro.Settings

  # describe "settings" do
  #   import PetalPro.SettingsFixtures

  #   alias PetalPro.Settings.Setting

  #   @invalid_attrs %{value: nil, description: nil, key: nil, type: nil, is_public: nil}

  #   test "list_settings/0 returns all settings" do
  #     setting = setting_fixture()
  #     assert Settings.list_settings() == [setting]
  #   end

  #   test "get_setting!/1 returns the setting with given id" do
  #     setting = setting_fixture()
  #     assert Settings.get_setting!(setting.id) == setting
  #   end

  #   test "create_setting/1 with valid data creates a setting" do
  #     valid_attrs = %{
  #       value: %{"value" => "some value"},
  #       description: "some description",
  #       key: "some_key",
  #       type: "string",
  #       is_public: true
  #     }

  #     assert {:ok, %Setting{} = setting} = Settings.create_setting(valid_attrs)
  #     assert setting.value == %{"value" => "some value"}
  #     assert setting.description == "some description"
  #     assert setting.key == "some_key"
  #     assert setting.type == "string"
  #     assert setting.is_public == true
  #   end

  #   test "create_setting/1 with invalid data returns error changeset" do
  #     assert {:error, %Ecto.Changeset{}} = Settings.create_setting(@invalid_attrs)
  #   end

  #   test "update_setting/2 with valid data updates the setting" do
  #     setting = setting_fixture()

  #     update_attrs = %{
  #       value: %{"value" => "some updated value"},
  #       description: "some updated description",
  #       key: "some_updated_key",
  #       type: "number",
  #       is_public: false
  #     }

  #     assert {:ok, %Setting{} = setting} = Settings.update_setting(setting, update_attrs)
  #     assert setting.value == %{"value" => "some updated value"}
  #     assert setting.description == "some updated description"
  #     assert setting.key == "some_updated_key"
  #     assert setting.type == "number"
  #     assert setting.is_public == false
  #   end

  #   test "update_setting/2 with invalid data returns error changeset" do
  #     setting = setting_fixture()
  #     assert {:error, %Ecto.Changeset{}} = Settings.update_setting(setting, @invalid_attrs)
  #     assert setting == Settings.get_setting!(setting.id)
  #   end

  #   test "delete_setting/1 deletes the setting" do
  #     setting = setting_fixture()
  #     assert {:ok, %Setting{}} = Settings.delete_setting(setting)
  #     assert_raise Ecto.NoResultsError, fn -> Settings.get_setting!(setting.id) end
  #   end

  #   test "change_setting/1 returns a setting changeset" do
  #     setting = setting_fixture()
  #     assert %Ecto.Changeset{} = Settings.change_setting(setting)
  #   end
  # end
end
