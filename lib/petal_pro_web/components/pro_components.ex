defmodule PetalProComponents do
  @moduledoc false
  defmacro __using__(_) do
    quote do
      import PetalProWeb.Aurora
      import PetalProWeb.AuthLayout
      import PetalProWeb.BorderBeam
      import PetalProWeb.ColorSchemeSwitch
      import PetalProWeb.ComboBox
      import PetalProWeb.ContentEditor
      import PetalProWeb.DataTable
      import PetalProWeb.Flash
      import PetalProWeb.FloatingDiv
      import PetalProWeb.LanguageSelect
      import PetalProWeb.LocalTime
      import PetalProWeb.Markdown
      import PetalProWeb.Navbar
      import PetalProWeb.PageComponents
      import PetalProWeb.RouteTree
      import PetalProWeb.SidebarLayout
      import PetalProWeb.SocialButton
      import PetalProWeb.StackedLayout
    end
  end
end
