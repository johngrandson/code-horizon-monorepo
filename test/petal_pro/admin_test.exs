defmodule PetalPro.AdminTest do
  use PetalPro.DataCase

  alias PetalPro.Admin

  describe "app_modules" do
    import PetalPro.AdminFixtures

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
      app_module = app_module_fixture()
      assert Admin.list_app_modules() == [app_module]
    end

    test "get_app_module!/1 returns the app_module with given id" do
      app_module = app_module_fixture()
      assert Admin.get_app_module!(app_module.id) == app_module
    end

    test "create_app_module/1 with valid data creates a app_module" do
      valid_attrs = %{
        code: "some code",
        name: "some name",
        status: :active,
        version: "some version",
        description: "some description",
        dependencies: ["option1", "option2"],
        price_id: "some price_id",
        is_white_label_ready: true,
        is_publicly_visible: true,
        setup_function: "some setup_function",
        cleanup_function: "some cleanup_function",
        routes_definition: %{}
      }

      assert {:ok, %AppModule{} = app_module} = Admin.create_app_module(valid_attrs)
      assert app_module.code == "some code"
      assert app_module.name == "some name"
      assert app_module.status == :active
      assert app_module.version == "some version"
      assert app_module.description == "some description"
      assert app_module.dependencies == ["option1", "option2"]
      assert app_module.price_id == "some price_id"
      assert app_module.is_white_label_ready == true
      assert app_module.is_publicly_visible == true
      assert app_module.setup_function == "some setup_function"
      assert app_module.cleanup_function == "some cleanup_function"
      assert app_module.routes_definition == %{}
    end

    test "create_app_module/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Admin.create_app_module(@invalid_attrs)
    end

    test "update_app_module/2 with valid data updates the app_module" do
      app_module = app_module_fixture()

      update_attrs = %{
        code: "some updated code",
        name: "some updated name",
        status: :inactive,
        version: "some updated version",
        description: "some updated description",
        dependencies: ["option1"],
        price_id: "some updated price_id",
        is_white_label_ready: false,
        is_publicly_visible: false,
        setup_function: "some updated setup_function",
        cleanup_function: "some updated cleanup_function",
        routes_definition: %{}
      }

      assert {:ok, %AppModule{} = app_module} = Admin.update_app_module(app_module, update_attrs)
      assert app_module.code == "some updated code"
      assert app_module.name == "some updated name"
      assert app_module.status == :inactive
      assert app_module.version == "some updated version"
      assert app_module.description == "some updated description"
      assert app_module.dependencies == ["option1"]
      assert app_module.price_id == "some updated price_id"
      assert app_module.is_white_label_ready == false
      assert app_module.is_publicly_visible == false
      assert app_module.setup_function == "some updated setup_function"
      assert app_module.cleanup_function == "some updated cleanup_function"
      assert app_module.routes_definition == %{}
    end

    test "update_app_module/2 with invalid data returns error changeset" do
      app_module = app_module_fixture()
      assert {:error, %Ecto.Changeset{}} = Admin.update_app_module(app_module, @invalid_attrs)
      assert app_module == Admin.get_app_module!(app_module.id)
    end

    test "delete_app_module/1 deletes the app_module" do
      app_module = app_module_fixture()
      assert {:ok, %AppModule{}} = Admin.delete_app_module(app_module)
      assert_raise Ecto.NoResultsError, fn -> Admin.get_app_module!(app_module.id) end
    end

    test "change_app_module/1 returns a app_module changeset" do
      app_module = app_module_fixture()
      assert %Ecto.Changeset{} = Admin.change_app_module(app_module)
    end
  end
end
