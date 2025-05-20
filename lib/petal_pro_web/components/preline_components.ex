defmodule PrelineComponents do
  @moduledoc """
  Módulo que agrupa todos os componentes baseados no Preline UI.

  ## Uso

  Adicione ao seu módulo de visualização ou live view:

      use PetalProWeb.PrelineComponents

  Isso importará todos os componentes do Preline disponíveis.
  """

  defmacro __using__(_) do
    quote do
      import PrelineComponents.FormComponents
    end
  end
end
