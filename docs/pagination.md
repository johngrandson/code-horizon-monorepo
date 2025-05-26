# Guia de Tabelas com Paginação

Este documento descreve como implementar tabelas com paginação no projeto usando a biblioteca Flop, incluindo configuração, métodos necessários e parâmetros de consulta.

## Visão Geral

O projeto utiliza a biblioteca [Flop](https://github.com/woylie/flop) para gerenciar paginação, ordenação e filtragem de dados em tabelas de forma consistente e eficiente.

## Configuração Básica

### Dependências

Certifique-se de que as seguintes dependências estão no seu `mix.exs`:

```elixir
defp deps do
  [
    # ...
    {:flop, "~> 0.20"},
    # ...
  ]
end
```

## Implementação Completa de uma Tabela com Paginação

### 1. Configuração no Contexto

Primeiro, certifique-se de que seu contexto está preparado para lidar com consultas paginadas:

```elixir
defmodule YourApp.YourContext do
  import Ecto.Query
  alias YourApp.Repo
  alias YourApp.YourSchema

  @doc """
  Lista os itens com suporte a paginação, ordenação e filtros.
  
  Parâmetros esperados:
  - `filters`: Mapa com os filtros a serem aplicados
  - `opts`: Opções adicionais para o Flop (limite, ordenação, etc.)
  
  Retorna:
  - `{:ok, {itens, meta}}` em caso de sucesso
  - `{:error, reason}` em caso de erro
  """
  def list_items(filters \\ %{}, opts \\ []) do
    base_query = from(i in YourSchema, where: ^filter_conditions(filters))
    
    Flop.validate_and_run(
      base_query,
      Map.get(opts, :flop, %{}),
      for: YourSchema,
      repo: Repo,
      default_limit: Map.get(opts, :default_limit, 10),
      default_order: %{
        order_by: [:inserted_at],
        order_directions: [:desc]
      }
    )
  end

  defp filter_conditions(filters) do
    filters
    |> Enum.reduce(dynamic(true), fn
      {:name, value}, dynamic when is_binary(value) and value != "" ->
        dynamic([i], ^dynamic and ilike(i.name, ^"%#{value}%"))
        
      {:status, status}, dynamic when status in ["active", "inactive"] ->
        dynamic([i], ^dynamic and i.status == ^status)
        
      {:inserted_after, %Date{} = date}, dynamic ->
        dynamic([i], ^dynamic and i.inserted_at >= ^date)
        
      _, dynamic ->
        dynamic
    end)
  end
  
  # Outras funções do contexto...
end
```

### 2. Configuração na LiveView

Na sua LiveView, você precisará implementar os seguintes callbacks e funções:

```elixir
defmodule YourAppWeb.YourLive.Index do
  use YourAppWeb, :live_view
  
  alias YourApp.YourContext
  alias YourApp.YourSchema
  
  # Número de itens por página
  @default_limit 10
  
  @impl true
  def mount(_params, _session, socket) do
    {:ok, 
      socket
      |> assign(:filters, %{})
      |> assign(:items, [])
      |> assign(:meta, nil)
      |> assign(:search_form, to_form(%{"search" => ""}))
      |> assign(:filters_form, to_form(%{}))
    }
  end
  
  @impl true
  def handle_params(params, _url, socket) do
    # Atualiza a URL e os parâmetros atuais
    socket = apply_action(socket, socket.assigns.live_action, params)
    
    # Aplica os filtros atuais e busca os itens
    socket = apply_filters(socket, params)
    
    {:noreply, socket}
  end
  
  # Atualiza os itens com base nos filtros atuais
  defp apply_filters(socket, params) do
    filters = socket.assigns.filters
    
    case YourContext.list_items(filters, flop: params, default_limit: @default_limit) do
      {:ok, {items, meta}} ->
        assign(socket, items: items, meta: meta)
        
      {:error, _reason} ->
        put_flash(socket, :error, "Erro ao carregar itens")
    end
  end
  
  # Manipulador de eventos para busca
  @impl true
  def handle_event("search", %{"search" => %{"query" => query}}, socket) do
    filters = Map.put(socket.assigns.filters, :name, query)
    
    {:noreply,
     socket
     |> assign(:filters, filters)
     |> push_patch(to: build_url(socket, filters, %{}))}
  end
  
  # Manipulador de eventos para filtros avançados
  @impl true
  def handle_event("apply_filters", %{"filters" => filter_params}, socket) do
    filters = 
      filter_params
      |> Enum.reduce(%{}, fn {key, value}, acc ->
        if value != "" do
          Map.put(acc, String.to_existing_atom(key), value)
        else
          acc
        end
      end)
    
    {:noreply,
     socket
     |> assign(:filters, filters)
     |> push_patch(to: build_url(socket, filters, %{}))}
  end
  
  # Manipulador de eventos para limpar filtros
  @impl true
  def handle_event("reset_filters", _, socket) do
    {:noreply,
     socket
     |> assign(:filters, %{})
     |> assign(:search_form, to_form(%{"search" => ""}))
     |> assign(:filters_form, to_form(%{}))
     |> push_patch(to: build_url(socket, %{}, %{}))}
  end
  
  # Manipulador de eventos para exclusão
  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    item = YourContext.get_item!(id)
    
    case YourContext.delete_item(item) do
      {:ok, _item} ->
        {:noreply,
         socket
         |> put_flash(:info, "Item excluído com sucesso")
         |> push_patch(to: build_url(socket, socket.assigns.filters, %{}))}
         
      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Erro ao excluir item")}
    end
  end
  
  # Constrói a URL com os parâmetros atuais
  defp build_url(socket, filters, params) do
    current_params = Map.merge(socket.assigns[:live_action_params] || %{}, params)
    current_path = socket.assigns.live_action
    
    # Remove parâmetros vazios
    params = 
      current_params
      |> Map.merge(filters)
      |> Enum.reject(fn {_, v} -> v == "" or is_nil(v) end)
      |> Map.new()
    
    Routes.your_route_path(socket, current_path, params)
  end
  
  # Formata a data para exibição
  defp format_date(nil), do: ""
  defp format_date(datetime), do: Calendar.strftime(datetime, "%d/%m/%Y %H:%M")
  
  # Verifica se há filtros ativos
  defp has_active_filters?(filters) do
    filters
    |> Map.drop([:order_by, :order_directions, :page, :page_size])
    |> map_size() > 0
  end
end
```

### 3. Template da LiveView

Aqui está um exemplo de template que inclui busca, filtros e a tabela paginada:

```heex
<div class="space-y-6">
  <!-- Cabeçalho com título e botão de adicionar -->
  <div class="flex justify-between items-center">
    <h1 class="text-2xl font-bold">Itens</h1>
    <.link 
      navigate={~p"/items/new"} 
      class="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-primary-600 hover:bg-primary-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary-500"
    >
      Adicionar Item
    </.link>
  </div>
  
  <!-- Barra de busca -->
  <div class="bg-white shadow rounded-lg p-4">
    <.form for={@search_form} phx-submit="search" class="flex space-x-4">
      <div class="flex-1">
        <.input 
          field={@search_form[:query]} 
          type="text" 
          placeholder="Buscar por nome..." 
          class="w-full"
        />
      </div>
      <button 
        type="submit" 
        class="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-primary-600 hover:bg-primary-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary-500"
      >
        Buscar
      </button>
    </.form>
    
    <!-- Filtros avançados -->
    <div class="mt-4">
      <.form for={@filters_form} phx-submit="apply_filters" class="space-y-4">
        <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
          <div>
            <.input 
              label="Status"
              field={@filters_form[:status]} 
              type="select" 
              options={[["Ativo", "active"], ["Inativo", "inactive"], ["Todos", ""]]}
              class="w-full"
            />
          </div>
          <div>
            <.input 
              label="Data mínima"
              field={@filters_form[:inserted_after]} 
              type="date" 
              class="w-full"
            />
          </div>
        </div>
        
        <div class="flex justify-between">
          <button 
            type="button" 
            phx-click="reset_filters"
            class="inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary-500"
          >
            Limpar filtros
          </button>
          
          <button 
            type="submit" 
            class="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-primary-600 hover:bg-primary-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary-500"
          >
            Aplicar filtros
          </button>
        </div>
      </.form>
    </div>
  </div>
  
  <!-- Tabela de itens -->
  <div class="bg-white shadow overflow-hidden sm:rounded-lg">
    <div class="overflow-x-auto">
      <.data_table
        id="items-table"
        meta={@meta}
        base_url_params={@filters}
      >
        <:col field={:id} label="ID" sortable />
        <:col field={:name} label="Nome" sortable>
          <.link 
            navigate={"/items/#{item.id}"}
            class="text-primary-600 hover:text-primary-900"
          >
            <%= item.name %>
          </.link>
        </:col>
        <:col field={:status} label="Status" sortable>
          <span class={
            "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium",
            if(item.status == "active", do: "bg-green-100 text-green-800", else: "bg-red-100 text-red-800")
          }>
            <%= String.capitalize(item.status) %>
          </span>
        </:col>
        <:col field={:inserted_at} label="Criado em" sortable>
          <%= format_date(item.inserted_at) %>
        </:col>
        <:col label="Ações">
          <div class="flex space-x-2">
            <.link 
              navigate={"/items/#{item.id}/edit"}
              class="text-primary-600 hover:text-primary-900"
            >
              <span class="sr-only">Editar</span>
              <Heroicons.pencil_alt class="h-5 w-5" />
            </.link>
            
            <button 
              type="button" 
              phx-click={show_modal("delete-item-#{item.id}")}
              class="text-red-600 hover:text-red-900"
            >
              <span class="sr-only">Excluir</span>
              <Heroicons.trash class="h-5 w-5" />
            </button>
            
            <.modal id={"delete-item-#{item.id}"}>
              <:title>Confirmar exclusão</:title>
              <p>Tem certeza que deseja excluir o item <strong><%= item.name %></strong>?</p>
              <div class="mt-6 flex justify-end space-x-3">
                <button 
                  type="button" 
                  phx-click={hide_modal("delete-item-#{item.id}")}
                  class="px-4 py-2 border border-gray-300 rounded-md text-sm font-medium text-gray-700 bg-white hover:bg-gray-50"
                >
                  Cancelar
                </button>
                <button 
                  type="button" 
                  phx-click="delete" 
                  phx-value-id={item.id}
                  class="px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-red-600 hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-red-500"
                >
                  Excluir
                </button>
              </div>
            </.modal>
          </div>
        </:col>
      </.data_table>
    </div>
    
    <!-- Informações de paginação -->
    <div class="px-4 py-3 flex items-center justify-between border-t border-gray-200 sm:px-6">
      <div class="flex-1 flex justify-between sm:hidden">
        <a 
          href="#" 
          class="relative inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50"
        >
          Anterior
        </a>
        <a 
          href="#" 
          class="ml-3 relative inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50"
        >
          Próxima
        </a>
      </div>
      <div class="hidden sm:flex-1 sm:flex sm:items-center sm:justify-between">
        <div>
          <p class="text-sm text-gray-700">
            Mostrando <span class="font-medium"><%= get_first_item_index(@meta) %></span>
            até <span class="font-medium"><%= get_last_item_index(@meta) %></span>
            de <span class="font-medium"><%= @meta.total_count %></span> resultados
          </p>
        </div>
        <div>
          <nav class="relative z-0 inline-flex rounded-md shadow-sm -space-x-px" aria-label="Pagination">
            <a 
              href={"#{@meta.path}?#{build_url_query(@meta, Map.merge(@filters, %{page: @meta.page - 1}))}"}
              class={[
                "relative inline-flex items-center px-2 py-2 rounded-l-md border border-gray-300 bg-white text-sm font-medium",
                if @meta.page == 1, do: "text-gray-300 cursor-not-allowed", else: "text-gray-500 hover:bg-gray-50"
              ]}
              aria-disabled={@meta.page == 1}
            >
              <span class="sr-only">Anterior</span>
              <Heroicons.chevron_left class="h-5 w-5" />
            </a>
            
            <%= for page <- (@meta.page-2)..(@meta.page+2), page > 0 and page <= @meta.total_pages do %>
              <a 
                href={"#{@meta.path}?#{build_url_query(@meta, Map.merge(@filters, %{page: page}))}"}
                class={
                  if page == @meta.page do
                    "z-10 bg-primary-50 border-primary-500 text-primary-600 relative inline-flex items-center px-4 py-2 border text-sm font-medium"
                  else
                    "bg-white border-gray-300 text-gray-500 hover:bg-gray-50 relative inline-flex items-center px-4 py-2 border text-sm font-medium"
                  end
                }
              >
                <%= page %>
              </a>
            <% end %>
            
            <a 
              href={"#{@meta.path}?#{build_url_query(@meta, Map.merge(@filters, %{page: @meta.page + 1}))}"}
              class={[
                "relative inline-flex items-center px-2 py-2 rounded-r-md border border-gray-300 bg-white text-sm font-medium",
                if @meta.page == @meta.total_pages, do: "text-gray-300 cursor-not-allowed", else: "text-gray-500 hover:bg-gray-50"
              ]}
              aria-disabled={@meta.page == @meta.total_pages}
            >
              <span class="sr-only">Próxima</span>
              <Heroicons.chevron_right class="h-5 w-5" />
            </a>
          </nav>
        </div>
      </div>
    </div>
  </div>
</div>
```

### 4. Configuração das Rotas

Certifique-se de que suas rotas estão configuradas corretamente:

```elixir
# lib/your_app_web/router.ex

defmodule YourAppWeb.Router do
  use YourAppWeb, :router
  
  # ... outras rotas ...
  
  scope "/", YourAppWeb do
    pipe_through [:browser, :require_authenticated_user]
    
    resources "/items", ItemController
    
    live "/items", ItemLive.Index, :index
    live "/items/new", ItemLive.Index, :new
    live "/items/:id", ItemLive.Show, :show
    live "/items/:id/edit", ItemLive.Index, :edit
  end
  
  # ... outras rotas ...
end
```

### 5. Funções Auxiliares

Adicione estas funções auxiliares ao final do seu módulo LiveView:

```elixir
defp get_first_item_index(meta) do
  if meta.page == 1 do
    1
  else
    (meta.page - 1) * meta.page_size + 1
  end
end

defp get_last_item_index(meta) do
  if meta.page * meta.page_size > meta.total_count do
    meta.total_count
  else
    meta.page * meta.page_size
  end
end

defp build_url_query(meta, params) do
  params = 
    params
    |> Map.merge(%{
      page: meta.page,
      page_size: meta.page_size,
      order_by: meta.order_by,
      order_directions: meta.order_directions
    })
    
  URI.encode_query(params)
end
```

## Parâmetros de Consulta Suportados

A tabela a seguir descreve todos os parâmetros de consulta suportados pelo Flop:

| Parâmetro         | Tipo     | Descrição                                                                 |
|-------------------|----------|-------------------------------------------------------------------------|
| `page`           | integer  | Número da página atual (padrão: 1)                                      |
| `page_size`      | integer  | Número de itens por página (padrão: definido em `default_limit`)        |
| `order_by`       | list     | Lista de campos para ordenação (ex: `["name", "inserted_at"]`)         |
| `order_directions` | list  | Lista de direções de ordenação (ex: `["asc", "desc"]`)                 |
| `filters`        | map      | Mapa de filtros a serem aplicados (ex: `%{"name" => "João"}`)           |

## Exemplo de Uso dos Filtros

### Filtro Simples

```elixir
# No contexto
YourContext.list_items(%{name: "João"})

```

### Filtro com Múltiplas Condições

```elixir
# No contexto
YourContext.list_items(%{
  name: "João",
  status: "active",
  inserted_after: ~D[2023-01-01]
})
```

### Ordenação

```elixir
# Ordenar por nome em ordem crescente
YourContext.list_items(%{}, %{
  order_by: ["name"],
  order_directions: ["asc"]
})

# Ordenar por data de criação (mais recentes primeiro) e depois por nome
YourContext.list_items(%{}, %{
  order_by: ["inserted_at", "name"],
  order_directions: ["desc", "asc"]
})
```

### Paginação

```elixir
# Página 2 com 20 itens por página
YourContext.list_items(%{}, %{
  page: 2,
  page_size: 20
})
```

## Considerações de Desempenho

1. **Índices no Banco de Dados**: Certifique-se de que os campos usados em `order_by` e nas condições de filtro tenham índices apropriados no banco de dados.

2. **Limite de Itens**: Defina um limite máximo razoável para `page_size` para evitar sobrecarga no banco de dados.

3. **Contagem de Itens**: A contagem total de itens pode ser cara em tabelas grandes. Considere usar `Flop.without_count/1` se a contagem não for necessária.

4. **Pré-carregamento**: Use `Ecto.assoc/2` e `preload` para evitar consultas N+1 ao carregar associações.

## Solução de Problemas

### A paginação não está funcionando

1. Verifique se você está passando o `meta` corretamente do contexto para o template.
2. Confirme se a consulta está retornando resultados.
3. Verifique se o `default_limit` está definido corretamente.
4. Certifique-se de que os parâmetros de URL estão sendo passados corretamente.

### A ordenação não está funcionando

1. Verifique se o campo está marcado como `sortable` na definição da coluna.
2. Confirme se o nome do campo corresponde ao nome da coluna no banco de dados.
3. Verifique se há índices nos campos de ordenação.

### Os filtros não estão sendo aplicados

1. Verifique se os nomes dos campos nos filtros correspondem aos nomes das colunas no banco de dados.
2. Confirme se os valores dos filtros não estão vazios ou nulos.
3. Verifique se a função `filter_conditions` está tratando corretamente os tipos de dados.

## Recursos Adicionais

- [Documentação do Flop](https://hexdocs.pm/flop/readme.html)
- [Exemplos de Uso](https://github.com/woylie/flop#usage)
- [Opções de Filtro](https://hexdocs.pm/flop/Flop.Filter.html)
- [Guia de Performance](https://hexdocs.pm/flop/performance.html)

### 1. Configuração na LiveView

Na sua LiveView, você precisará:

1. Importar os módulos necessários:

```elixir
alias PetalProWeb.DataTable
import PetalComponents.Pagination
```

2. Configurar a consulta inicial e opções:

```elixir
@impl true
def mount(_params, _session, socket) do
  {:ok, assign(socket, items: [], meta: nil)}
end

@impl true
def handle_params(params, _url, socket) do
  starting_query = YourContext.list_your_schema()

  flop_opts = [
    default_limit: 10,
    default_order: %{
      order_by: [:inserted_at],
      order_directions: [:desc]
    }
  ]

  socket =
    case Flop.validate_and_run(starting_query, params, flop_opts) do
      {:ok, {items, meta}} ->
        assign(socket, %{
          items: items,
          meta: meta
        })

      _ ->
        push_navigate(socket, to: ~p"/your-route")
    end

  {:noreply, socket}
end
```

### 2. Renderização da Tabela

No seu template, use o componente `data_table`:

```heex
<div class="overflow-x-auto">
  <.data_table
    id="items-table"
    meta={@meta}
    base_url_params={%{}}
  >
    <:col field={:id} label="ID" sortable />
    <:col field={:name} label="Nome" sortable />
    <:col field={:inserted_at} label="Criado em" sortable>
      <%= Calendar.strftime(item.inserted_at, "%d/%m/%Y %H:%M") %>
    </:col>
  </.data_table>
</div>
```

## Recursos Avançados

### Ordenação

Adicione `sortable` nas colunas que devem ser ordenáveis:

```heex
<:col field={:name} label="Nome" sortable />
```

### Filtros

Para adicionar filtros, você pode usar o parâmetro `filters`:

```heex
<.data_table
  id="items-table"
  meta={@meta}
  base_url_params={%{}}
  filters={[
    %{
      field: :name,
      op: :ilike,
      value: @filters["name"] || ""
    }
  ]}
>
  <!-- colunas -->
</.data_table>
```

### Personalização

#### Itens por Página

Altere o número padrão de itens por página:

```elixir
flop_opts = [
  default_limit: 25,  # Mude para o número desejado
  # ...
]
```

#### Ordenação Padrão

Defina a ordenação padrão:

```elixir
flop_opts = [
  default_order: %{
    order_by: [:name],
    order_directions: [:asc]
  }
  # ...
]
```

## Solução de Problemas

### A paginação não está funcionando

1. Verifique se você está passando o `meta` corretamente para o componente
2. Confirme se sua consulta está retornando os resultados esperados
3. Verifique se o `default_limit` está definido corretamente

### A ordenação não está funcionando

1. Certifique-se de que o campo está marcado como `sortable`
2. Verifique se o nome do campo corresponde ao nome da coluna no banco de dados

## Recursos Adicionais

- [Documentação do Flop](https://hexdocs.pm/flop/readme.html)
- [Exemplos de Uso](https://github.com/woylie/flop#usage)
- [Opções de Filtro](https://hexdocs.pm/flop/Flop.Filter.html)
