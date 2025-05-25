defmodule PetalProWeb.AppModuleLiveTest do
  use PetalProWeb.ConnCase

  import Phoenix.LiveViewTest
  import PetalPro.AppModulesFixtures

  @create_attrs %{AppModules: "some AppModules"}
  @update_attrs %{AppModules: "some updated AppModules"}
  @invalid_attrs %{AppModules: nil}

  defp create_app_module(_) do
    app_module = app_module_fixture()
    %{app_module: app_module}
  end

  describe "Index" do
    setup [:create_app_module]

    test "lists all app_modules", %{conn: conn, app_module: app_module} do
      {:ok, _index_live, html} = live(conn, ~p"/app_modules")

      assert html =~ "Listing App modules"
      assert html =~ app_module.AppModules
    end

    test "saves new app_module", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/app_modules")

      assert index_live |> element("a", "New App module") |> render_click() =~
               "New App module"

      assert_patch(index_live, ~p"/app_modules/new")

      assert index_live
             |> form("#app_module-form", app_module: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#app_module-form", app_module: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/app_modules")

      html = render(index_live)
      assert html =~ "App module created successfully"
      assert html =~ "some AppModules"
    end

    test "updates app_module in listing", %{conn: conn, app_module: app_module} do
      {:ok, index_live, _html} = live(conn, ~p"/app_modules")

      assert index_live |> element("#app_modules-#{app_module.id} a", "Edit") |> render_click() =~
               "Edit App module"

      assert_patch(index_live, ~p"/app_modules/#{app_module}/edit")

      assert index_live
             |> form("#app_module-form", app_module: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#app_module-form", app_module: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/app_modules")

      html = render(index_live)
      assert html =~ "App module updated successfully"
      assert html =~ "some updated AppModules"
    end

    test "deletes app_module in listing", %{conn: conn, app_module: app_module} do
      {:ok, index_live, _html} = live(conn, ~p"/app_modules")

      assert index_live |> element("#app_modules-#{app_module.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#app_modules-#{app_module.id}")
    end
  end

  describe "Show" do
    setup [:create_app_module]

    test "displays app_module", %{conn: conn, app_module: app_module} do
      {:ok, _show_live, html} = live(conn, ~p"/app_modules/#{app_module}")

      assert html =~ "Show App module"
      assert html =~ app_module.AppModules
    end

    test "updates app_module within modal", %{conn: conn, app_module: app_module} do
      {:ok, show_live, _html} = live(conn, ~p"/app_modules/#{app_module}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit App module"

      assert_patch(show_live, ~p"/app_modules/#{app_module}/show/edit")

      assert show_live
             |> form("#app_module-form", app_module: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#app_module-form", app_module: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/app_modules/#{app_module}")

      html = render(show_live)
      assert html =~ "App module updated successfully"
      assert html =~ "some updated AppModules"
    end
  end
end
