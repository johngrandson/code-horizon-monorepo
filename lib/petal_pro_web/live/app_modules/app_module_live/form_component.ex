defmodule PetalProWeb.AdminAppModuleLive.FormComponent do
  @moduledoc false
  use PetalProWeb, :live_component

  alias PetalPro.AppModules

  @impl true
  def update(%{app_module: app_module} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(AppModules.change_app_module(app_module))
     end)}
  end

  @impl true
  def handle_event("validate", %{"app_module" => app_module_params}, socket) do
    changeset =
      socket.assigns.app_module
      |> AppModules.change_app_module(app_module_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset))}
  end

  def handle_event("save", %{"app_module" => app_module_params}, socket) do
    save_app_module(socket, socket.assigns.action, app_module_params)
  end

  defp save_app_module(socket, :edit, app_module_params) do
    case AppModules.update_app_module(socket.assigns.app_module, app_module_params) do
      {:ok, _app_module} ->
        {:noreply,
         socket
         |> put_flash(:info, "App module updated successfully")
         |> push_navigate(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_app_module(socket, :new, app_module_params) do
    case AppModules.create_app_module(app_module_params) do
      {:ok, _app_module} ->
        {:noreply,
         socket
         |> put_flash(:info, "App module created successfully")
         |> push_navigate(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end
end
