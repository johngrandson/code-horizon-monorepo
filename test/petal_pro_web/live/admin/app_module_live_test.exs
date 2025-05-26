defmodule PetalProWeb.AdminAppModuleLiveTest do
  use PetalProWeb.ConnCase

  import PetalPro.AppModuleFixtures
  import Phoenix.LiveViewTest

  @create_attrs %{
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
  @update_attrs %{
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
  @invalid_attrs %{
    code: nil,
    name: nil,
    status: nil,
    version: nil,
    description: nil,
    dependencies: [],
    price_id: nil,
    is_white_label_ready: false,
    is_publicly_visible: false,
    setup_function: nil,
    cleanup_function: nil,
    routes_definition: nil
  }

  defp create_app_module(_) do
    app_module = app_module_fixture()
    %{app_module: app_module}
  end

  describe "Index" do
    setup [:create_app_module]

    test "lists all app_modules", %{conn: conn, app_module: app_module} do
      {:ok, _index_live, html} = live(conn, ~p"/admin/app_modules")

      assert html =~ "Listing App modules"
      assert html =~ app_module.code
    end

    test "saves new app_module", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/admin/app_modules")

      assert index_live |> element("a", "New App module") |> render_click() =~
               "New App module"

      assert_patch(index_live, ~p"/admin/app_modules/new")

      assert index_live
             |> form("#app_module-form", app_module: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        index_live
        |> form("#app_module-form", app_module: @create_attrs)
        |> render_submit()
        |> follow_redirect(conn, ~p"/admin/app_modules")

      assert html =~ "App module created successfully"
      assert html =~ "some code"
    end

    test "updates app_module in listing", %{conn: conn, app_module: app_module} do
      {:ok, index_live, _html} = live(conn, ~p"/admin/app_modules")

      assert index_live |> element("a[href='/app_modules/#{app_module.id}/edit']", "Edit") |> render_click() =~
               "Edit App module"

      assert_patch(index_live, ~p"/admin/app_modules/#{app_module}/edit")

      assert index_live
             |> form("#app_module-form", app_module: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        index_live
        |> form("#app_module-form", app_module: @update_attrs)
        |> render_submit()
        |> follow_redirect(conn, ~p"/admin/app_modules")

      assert html =~ "App module updated successfully"
      assert html =~ "some updated code"
    end

    test "deletes app_module in listing", %{conn: conn, app_module: app_module} do
      {:ok, index_live, _html} = live(conn, ~p"/admin/app_modules")

      assert index_live |> element("a[phx-value-id=#{app_module.id}]", "Delete") |> render_click()
      refute has_element?(index_live, "a[phx-value-id=#{app_module.id}]")
    end
  end

  describe "Show" do
    setup [:create_app_module]

    test "displays app_module", %{conn: conn, app_module: app_module} do
      {:ok, _show_live, html} = live(conn, ~p"/admin/app_modules/#{app_module}")

      assert html =~ "Show App module"
      assert html =~ app_module.code
    end

    test "updates app_module within modal", %{conn: conn, app_module: app_module} do
      {:ok, show_live, _html} = live(conn, ~p"/admin/app_modules/#{app_module}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit App module"

      assert_patch(show_live, ~p"/admin/app_modules/#{app_module}/show/edit")

      assert show_live
             |> form("#app_module-form", app_module: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      {:ok, _, html} =
        show_live
        |> form("#app_module-form", app_module: @update_attrs)
        |> render_submit()
        |> follow_redirect(conn, ~p"/admin/app_modules/#{app_module}")

      assert html =~ "App module updated successfully"
      assert html =~ "some updated code"
    end
  end
end
