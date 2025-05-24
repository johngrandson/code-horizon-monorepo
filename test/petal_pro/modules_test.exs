defmodule PetalPro.ModulesTest do
  use PetalPro.DataCase

  alias PetalPro.Modules

  describe "modules" do
    alias PetalPro.Modules.Module

    import PetalPro.ModulesFixtures

    @invalid_attrs %{code: nil, name: nil, status: nil, version: nil, description: nil, dependencies: nil, price_id: nil, is_white_label_ready: nil, is_publicly_visible: nil, setup_function: nil, cleanup_function: nil, routes_definition: nil}

    test "list_modules/0 returns all modules" do
      module = module_fixture()
      assert Modules.list_modules() == [module]
    end

    test "get_module!/1 returns the module with given id" do
      module = module_fixture()
      assert Modules.get_module!(module.id) == module
    end

    test "create_module/1 with valid data creates a module" do
      valid_attrs = %{code: "some code", name: "some name", status: "some status", version: "some version", description: "some description", dependencies: "some dependencies", price_id: "some price_id", is_white_label_ready: true, is_publicly_visible: true, setup_function: "some setup_function", cleanup_function: "some cleanup_function", routes_definition: "some routes_definition"}

      assert {:ok, %Module{} = module} = Modules.create_module(valid_attrs)
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

    test "create_module/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Modules.create_module(@invalid_attrs)
    end

    test "update_module/2 with valid data updates the module" do
      module = module_fixture()
      update_attrs = %{code: "some updated code", name: "some updated name", status: "some updated status", version: "some updated version", description: "some updated description", dependencies: "some updated dependencies", price_id: "some updated price_id", is_white_label_ready: false, is_publicly_visible: false, setup_function: "some updated setup_function", cleanup_function: "some updated cleanup_function", routes_definition: "some updated routes_definition"}

      assert {:ok, %Module{} = module} = Modules.update_module(module, update_attrs)
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

    test "update_module/2 with invalid data returns error changeset" do
      module = module_fixture()
      assert {:error, %Ecto.Changeset{}} = Modules.update_module(module, @invalid_attrs)
      assert module == Modules.get_module!(module.id)
    end

    test "delete_module/1 deletes the module" do
      module = module_fixture()
      assert {:ok, %Module{}} = Modules.delete_module(module)
      assert_raise Ecto.NoResultsError, fn -> Modules.get_module!(module.id) end
    end

    test "change_module/1 returns a module changeset" do
      module = module_fixture()
      assert %Ecto.Changeset{} = Modules.change_module(module)
    end
  end
end
