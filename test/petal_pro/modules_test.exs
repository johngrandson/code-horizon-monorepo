defmodule PetalPro.ModulesTest do
  use PetalPro.DataCase

  alias PetalPro.AppModules

  describe "app_modules" do
    import PetalPro.AppModulesFixtures

    alias PetalPro.AppModules.AppModule

    @invalid_attrs %{
      code: nil,
      name: nil,
      status: nil,
      version: nil,
      description: nil,
      dependencies: nil,
      price_id: nil,
      is_white_label_ready: nil,
      is_publicly_visible: nil,
      setup_function: nil,
      cleanup_function: nil,
      routes_definition: nil
    }

    test "list_app_modules/0 returns all app_modules" do
      module = module_fixture()
      assert AppModules.list_app_modules() == [module]
    end

    test "get_app_module!/1 returns the app_module with given id" do
      module = module_fixture()
      assert AppModules.get_app_module!(module.id) == module
    end

    test "create_app_module/1 with valid data creates a app_module" do
      valid_attrs = %{
        code: "some code",
        name: "some name",
        status: "some status",
        version: "some version",
        description: "some description",
        dependencies: "some dependencies",
        price_id: "some price_id",
        is_white_label_ready: true,
        is_publicly_visible: true,
        setup_function: "some setup_function",
        cleanup_function: "some cleanup_function",
        routes_definition: "some routes_definition"
      }

      assert {:ok, %AppModule{} = module} = AppModules.create_app_module(valid_attrs)
      assert module.code == "some code"
      assert module.name == "some name"
      assert module.status == "some status"
      assert module.version == "some version"
      assert module.description == "some description"
      assert module.dependencies == "some dependencies"
      assert module.price_id == "some price_id"
      assert module.is_white_label_ready == true
      assert module.is_publicly_visible == true
      assert module.setup_function == "some setup_function"
      assert module.cleanup_function == "some cleanup_function"
      assert module.routes_definition == "some routes_definition"
    end

    test "create_app_module/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = AppModules.create_app_module(@invalid_attrs)
    end

    test "update_app_module/2 with valid data updates the app_module" do
      module = module_fixture()

      update_attrs = %{
        code: "some updated code",
        name: "some updated name",
        status: "some updated status",
        version: "some updated version",
        description: "some updated description",
        dependencies: "some updated dependencies",
        price_id: "some updated price_id",
        is_white_label_ready: false,
        is_publicly_visible: false,
        setup_function: "some updated setup_function",
        cleanup_function: "some updated cleanup_function",
        routes_definition: "some updated routes_definition"
      }

      assert {:ok, %AppModule{} = module} = AppModules.update_app_module(module, update_attrs)
      assert module.code == "some updated code"
      assert module.name == "some updated name"
      assert module.status == "some updated status"
      assert module.version == "some updated version"
      assert module.description == "some updated description"
      assert module.dependencies == "some updated dependencies"
      assert module.price_id == "some updated price_id"
      assert module.is_white_label_ready == false
      assert module.is_publicly_visible == false
      assert module.setup_function == "some updated setup_function"
      assert module.cleanup_function == "some updated cleanup_function"
      assert module.routes_definition == "some updated routes_definition"
    end

    test "update_app_module/2 with invalid data returns error changeset" do
      module = module_fixture()
      assert {:error, %Ecto.Changeset{}} = AppModules.update_app_module(module, @invalid_attrs)
      assert module == AppModules.get_app_module!(module.id)
    end

    test "delete_app_module/1 deletes the app_module" do
      module = module_fixture()
      assert {:ok, %AppModule{}} = AppModules.delete_app_module(module)
      assert_raise Ecto.NoResultsError, fn -> AppModules.get_app_module!(module.id) end
    end

    test "change_app_module/1 returns a app_module changeset" do
      module = module_fixture()
      assert %Ecto.Changeset{} = AppModules.change_app_module(module)
    end
  end
end
