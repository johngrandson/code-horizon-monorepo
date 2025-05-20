defmodule PetalProWeb.Admin.AdminSettingLiveTest do
  use PetalProWeb.ConnCase

  import PetalPro.SettingsFixtures
  import Phoenix.LiveViewTest

  alias PetalPro.Settings

  @create_attrs %{
    key: "test_key_#{System.unique_integer([:positive])}",
    value: %{"value" => "test_value"},
    description: "Test description",
    type: "string",
    is_public: false
  }

  defp create_setting(_) do
    setting = setting_fixture()
    %{setting: setting}
  end

  describe "Index" do
    setup [:register_and_sign_in_admin, :create_setting]

    test "lists all settings", %{conn: conn, setting: setting} do
      {:ok, _view, html} = live(conn, ~p"/admin/settings")

      assert html =~ "Global App Settings"
      assert html =~ setting.key
      assert html =~ get_in(setting.value, ["value"])
      assert html =~ setting.description
    end
  end
end
