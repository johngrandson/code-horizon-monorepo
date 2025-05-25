defmodule PetalPro.AppModulesTest do
  use PetalPro.DataCase

  alias PetalPro.AppModules

  describe "app_modules" do
    alias PetalPro.AppModules.AppModule

    import PetalPro.AppModulesFixtures

    @invalid_attrs %{AppModules: nil}

    test "list_app_modules/0 returns all app_modules" do
      app_module = app_module_fixture()
      assert AppModules.list_app_modules() == [app_module]
    end

    test "get_app_module!/1 returns the app_module with given id" do
      app_module = app_module_fixture()
      assert AppModules.get_app_module!(app_module.id) == app_module
    end

    test "create_app_module/1 with valid data creates a app_module" do
      valid_attrs = %{AppModules: "some AppModules"}

      assert {:ok, %AppModule{} = app_module} = AppModules.create_app_module(valid_attrs)
      assert app_module.AppModules == "some AppModules"
    end

    test "create_app_module/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = AppModules.create_app_module(@invalid_attrs)
    end

    test "update_app_module/2 with valid data updates the app_module" do
      app_module = app_module_fixture()
      update_attrs = %{AppModules: "some updated AppModules"}

      assert {:ok, %AppModule{} = app_module} = AppModules.update_app_module(app_module, update_attrs)
      assert app_module.AppModules == "some updated AppModules"
    end

    test "update_app_module/2 with invalid data returns error changeset" do
      app_module = app_module_fixture()
      assert {:error, %Ecto.Changeset{}} = AppModules.update_app_module(app_module, @invalid_attrs)
      assert app_module == AppModules.get_app_module!(app_module.id)
    end

    test "delete_app_module/1 deletes the app_module" do
      app_module = app_module_fixture()
      assert {:ok, %AppModule{}} = AppModules.delete_app_module(app_module)
      assert_raise Ecto.NoResultsError, fn -> AppModules.get_app_module!(app_module.id) end
    end

    test "change_app_module/1 returns a app_module changeset" do
      app_module = app_module_fixture()
      assert %Ecto.Changeset{} = AppModules.change_app_module(app_module)
    end
  end
end
