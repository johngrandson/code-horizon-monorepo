defmodule PetalPro.AppModules.Registry do
  @moduledoc """
  Central registry for all available application modules.
  Responsible for discovering and tracking module implementations.
  """

  @behaviour_module PetalPro.AppModules.Behaviours.AppModule

  @doc """
  Returns all modules implementing the Module behavior.
  This implementation uses a more reliable method to check for behavior implementation.
  """
  def list_app_module_implementations do
    for {module, _} <- :code.all_loaded(),
        implements_app_module_behaviour?(module),
        do: module
  end

  @doc """
  Returns a specific module implementation by its code.
  """
  def get_app_module_by_code(code) when is_binary(code) do
    Enum.find(list_app_module_implementations(), fn module -> module.code() == code end)
  end

  # Improved implementation for checking if a module implements the Module behavior.
  defp implements_app_module_behaviour?(module) do
    with true <- Code.ensure_loaded?(module),
         behaviours when is_list(behaviours) <- app_module_behaviours(module) do
      @behaviour_module in behaviours
    else
      _ -> false
    end
  end

  # Helper to safely get module behaviors
  defp app_module_behaviours(module) do
    module.module_info()[:attributes][:behaviour] || []
  rescue
    # Handle case where module doesn't support module_info
    _ -> []
  end
end
