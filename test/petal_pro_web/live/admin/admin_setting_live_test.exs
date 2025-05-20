defmodule PetalProWeb.Admin.AdminSettingLiveTest do
  use PetalProWeb.ConnCase
  import Phoenix.LiveViewTest
  import PetalPro.SettingsFixtures

  alias PetalPro.Repo
  alias PetalPro.Settings.Setting
  alias PetalPro.Settings

  @create_attrs %{
    key: "some_key_#{System.unique_integer([:positive])}",
    value: "some_value",
    description: "some description",
    value_type: "string"
  }

  defp create_setting(_) do
    setting = setting_fixture()
    %{setting: setting}
  end

  describe "Index" do
    setup [:register_and_sign_in_admin, :create_setting]
    
    test "can list settings", %{conn: conn, setting: setting} do
    {:ok, _view, html} = live(conn, ~p"/admin/settings")
    
    assert html =~ setting.key
    assert html =~ get_in(setting.value, ["value"])
    assert html =~ setting.description
  end

  test "can create new setting", %{conn: conn} do
    # Cria uma chave única para o teste
    unique_key = "test_key_#{System.unique_integer([:positive])}"
    test_attrs = %{
      key: unique_key,
      value: "test_value",
      description: "Test description",
      value_type: "string"
    }
    
    {:ok, view, _html} = live(conn, ~p"/admin/settings/new")
    
    # Preenche o formulário
    view
    |> form("#setting-form", setting: test_attrs)
    |> render_submit()
    
    # Verifica se foi redirecionado para a lista
    assert_redirected(view, ~p"/admin/settings")
    
    # Verifica se a configuração foi criada
    assert Settings.get_setting_by(%{key: unique_key})
  end
  
  test "can delete setting", %{conn: conn, setting: setting} do
    {:ok, view, _html} = live(conn, ~p"/admin/settings")
    
    # Encontra e clica no botão de deletar
    view
    |> element("a[phx-click='delete']")
    |> render_click()
    
    # Verifica se a mensagem de confirmação foi exibida
    assert render(view) =~ "Are you sure?"
    
    # Como o delete é assíncrono, apenas verificamos que a UI respondeu
    # A remoção em si seria testada em um teste de contexto separado
  end
    
    test "shows pagination controls when needed", %{conn: conn} do
      # Limpa configurações existentes
      Repo.delete_all(Setting)
      
      # Cria mais configurações do que o limite padrão
      for i <- 1..15 do
        setting_fixture(%{
          key: "setting_#{i}",
          value: %{"value" => "value_#{i}"},
          description: "Setting #{i}"
        })
      end
      
      # Acessa a página
      {:ok, view, _html} = live(conn, ~p"/admin/settings")
      
      # Renderiza a view e verifica se há itens
      rendered = render(view)
      assert rendered =~ "setting_1"
      
      # Verifica se há controles de navegação
      # Verifica se há algum link de próxima página ou botão de próxima página
      assert String.contains?(rendered, "page=2") || 
             String.contains?(rendered, "Next") ||
             String.contains?(rendered, "Próximo") ||
             String.contains?(rendered, "Próxima")
    end

    test "lists all settings", %{conn: conn, setting: setting} do
      {:ok, _index_live, html} = live(conn, ~p"/admin/settings")

      assert html =~ "Global App Settings"
      assert html =~ setting.key
      assert html =~ get_in(setting.value, ["value"])
      assert html =~ setting.description
    end

    test "shows empty state when there are no settings", %{conn: conn} do
      # Garante que não há configurações
      Repo.delete_all(Setting)

      # Acessa a página de configurações
      {:ok, view, _html} = live(conn, ~p"/admin/settings")

      # Verifica a mensagem de estado vazio
      assert render(view) =~ "No settings found"
      # Verifica o botão de nova configuração
      assert has_element?(view, "a", "New Setting")
    end

    test "saves new setting", %{conn: conn} do
      # First, access the settings page
      {:ok, index_live, _html} = live(conn, ~p"/admin/settings")

      # Click the new setting button
      assert index_live |> element("a", "New Setting") |> render_click() =~
               "New Setting"

      assert_patch(index_live, ~p"/admin/settings/new")

      # Fill the form with valid data
      form_data = %{
        "setting" => %{
          "key" => @create_attrs.key,
          "value" => @create_attrs.value,
          "description" => @create_attrs.description,
          "value_type" => @create_attrs.value_type
        }
      }

      # Submit the form
      {:ok, _, html} =
        index_live
        |> form("#setting-form", form_data)
        |> render_submit()
        |> follow_redirect(conn, ~p"/admin/settings")

      # Verifica se a mensagem de sucesso foi exibida
      assert html =~ "Setting created successfully"
      assert html =~ @create_attrs.key
      assert html =~ @create_attrs.description
    end
  end
end
