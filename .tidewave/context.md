# Documentação de Contexto: Petal Pro Multi-Tenant Platform

## 1. Visão Geral & Arquitetura

O projeto consiste em uma plataforma multi-tenant white-label construída sobre o framework Petal Pro, que utiliza a stack PETAL (Phoenix, Elixir, TailwindCSS, Alpine.js, LiveView). A arquitetura segue os princípios de design da Clean Architecture e Domain-Driven Design, organizando o código em contextos bem definidos com interfaces claras.

```
lib/
├── petal_pro/                # Core business logic
│   ├── accounts/             # User authentication and management
│   ├── orgs/                 # Organization context with memberships
│   ├── billing/              # Subscription management with Stripe
│   │
│   ├── multi_tenant/         # Multi-tenant implementation
│   │   ├── tenants.ex        # Tenant management API
│   │   ├── tenant.ex         # Tenant schema
│   │   └── schema_manager.ex # Schema isolation logic
│   │
│   ├── modules/              # Module system
│   │   ├── registry.ex       # Module registration
│   │   ├── behaviours/       # Module interfaces
│   │   └── authorizer.ex     # Access control
│   │
│   └── app_modules/          # Actual application modules
│       ├── crm/              # CRM module
│       ├── cms/              # CMS module
│       └── blog/             # Blog module
│
└── petal_pro_web/            # Web interface layer
    ├── components/           # Shared UI components
    ├── plugs/                # HTTP middleware
    ├── on_mount/             # LiveView hooks
    └── live/                 # LiveView interfaces
```

## 2. Uso de Generators e Padrões do Petal Pro

### 2.1 Importância dos Generators

O Petal Pro fornece um robusto sistema de generators que **devem ser utilizados obrigatoriamente** para manter a consistência do código. Este é um aspecto fundamental para o desenvolvimento no projeto.

```bash
# Criar um novo contexto e schema
mix petal.gen.context Tenants Tenant tenants name:string slug:string:unique status:enum:active:inactive:suspended org_id:references:orgs

# Criar um novo LiveView
mix petal.gen.live Tenants Tenant tenants name:string slug:string status:enum org_id:references:orgs
```

Os generators do Petal Pro criam automaticamente:
- Arquivos de contexto seguindo o padrão do framework
- Schemas com tipos fortes via TypedEctoSchema
- Funções CRUD padronizadas
- LiveViews com DataTable e componentes
- Testes automatizados

### 2.2 Padrões de Codificação

Todo desenvolvimento deve seguir estritamente os padrões e convenções do Petal Pro:

```elixir
# Schema pattern with typed_schema macro
defmodule PetalPro.MultiTenant.Tenant do
  use PetalPro.Schema  # Includes QueryBuilder, typed_schema, etc.

  typed_schema "tenants" do
    field :name, :string
    field :slug, :string, unique: true
    field :status, Ecto.Enum, values: [:active, :inactive, :suspended]
    
    belongs_to :org, PetalPro.Orgs.Org
    
    timestamps()
  end
  
  # Always use changeset functions for validations
  def changeset(tenant, attrs) do
    tenant
    |> cast(attrs, [:name, :slug, :status, :org_id])
    |> validate_required([:name, :slug, :status])
    |> unique_constraint(:slug)
  end
end

# Context pattern with standardized API
defmodule PetalPro.MultiTenant.Tenants do
  import Ecto.Query
  alias PetalPro.Repo
  alias PetalPro.MultiTenant.Tenant
  
  # Standard CRUD functions
  def list_tenants(filters \\ []), do: Tenant |> apply_filters(filters) |> Repo.all()
  def get_tenant!(id), do: Repo.get!(Tenant, id)
  def create_tenant(attrs), do: %Tenant{} |> Tenant.changeset(attrs) |> Repo.insert()
  def update_tenant(%Tenant{} = tenant, attrs), do: tenant |> Tenant.changeset(attrs) |> Repo.update()
  def delete_tenant(%Tenant{} = tenant), do: Repo.delete(tenant)
  def change_tenant(%Tenant{} = tenant, attrs \\ %{}), do: Tenant.changeset(tenant, attrs)
end
```

## 3. Arquitetura Multi-Tenant

A implementação multi-tenant do projeto usa o padrão de isolamento por schema PostgreSQL via Triplex:

### 3.1 Isolamento de Dados

Três níveis de isolamento são suportados:
1. **Shared**: Múltiplos tenants compartilham tabelas (filtrados por tenant_id)
2. **Isolated**: Cada tenant possui seu próprio schema PostgreSQL
3. **Enterprise**: Configuração avançada para clientes que exigem banco dedicado

```elixir
# Schema definition
typed_schema "tenants" do
  field :name, :string
  field :slug, :string, unique: true
  field :isolation_type, Ecto.Enum, values: [:shared, :isolated, :enterprise]
  field :schema_prefix, :string  # For isolated tenants
  field :db_config, :map         # For enterprise tenants
  
  # Relationships
  belongs_to :org, PetalPro.Orgs.Org
  belongs_to :parent_tenant, PetalPro.MultiTenant.Tenant
  
  has_many :domains, PetalPro.MultiTenant.Domain
  has_many :child_tenants, PetalPro.MultiTenant.Tenant, foreign_key: :parent_tenant_id
  has_one :theme, PetalPro.WhiteLabel.Theme
  has_many :module_subscriptions, PetalPro.Modules.ModuleSubscription
  
  timestamps()
end
```

### 3.2 Detecção de Tenant

A detecção de tenant é baseada no domínio da requisição:

```elixir
defmodule PetalProWeb.Plugs.TenantDetector do
  import Plug.Conn
  
  def call(conn, _opts) do
    host = conn.host
    tenant = PetalPro.MultiTenant.Tenants.get_tenant_by_domain(host)
    
    conn
    |> assign(:current_tenant, tenant || get_default_tenant())
    |> put_tenant_in_process(tenant)
  end
  
  defp put_tenant_in_process(conn, tenant) do
    if tenant do
      Process.put(:current_tenant, tenant)
      Process.put(:current_tenant_id, tenant.id)
    end
    
    conn
  end
end
```

## 4. Sistema de Módulos

A arquitetura modular permite que funcionalidades sejam ativadas por tenant, implementando o padrão de comportamento (behaviour):

```elixir
defmodule PetalPro.Modules.Behaviours.Module do
  @callback code() :: String.t()
  @callback name() :: String.t() 
  @callback description() :: String.t()
  @callback version() :: String.t()
  @callback dependencies() :: [String.t()]
  
  @callback setup_tenant(tenant_id :: integer, opts :: keyword) :: :ok | {:error, term()}
  @callback cleanup_tenant(tenant_id :: integer) :: :ok | {:error, term()}
  
  @callback routes() :: map()
  
  # Optional callbacks
  @callback dashboard_widgets() :: [map()]
  @callback sidebar_menu() :: [map()]
  @callback user_roles() :: [map()]
  
  @optional_callbacks [
    dashboard_widgets: 0,
    sidebar_menu: 0,
    user_roles: 0
  ]
end
```

### 4.1 Implementação de Módulo

Cada módulo funcional deve seguir a implementação do comportamento:

```elixir
# Example module implementation
defmodule PetalPro.AppModules.CRM do
  @behaviour PetalPro.Modules.Behaviours.Module
  
  # Public API functions that delegate to internal contexts
  alias PetalPro.AppModules.CRM.{Contacts, Deals, Activities}
  
  @impl true
  def code, do: "crm"
  
  @impl true
  def name, do: "CRM"
  
  @impl true
  def description, do: "Customer Relationship Management"
  
  @impl true
  def version, do: "1.0.0"
  
  @impl true
  def dependencies, do: []
  
  @impl true
  def setup_tenant(tenant_id, _opts \\ []) do
    # Initialize tenant-specific data
    :ok
  end
  
  @impl true
  def cleanup_tenant(tenant_id) do
    # Clean up tenant data
    :ok
  end
  
  @impl true
  def routes do
    %{
      main_route: "/crm",
      menu_items: [
        %{label: "Dashboard", path: "/crm", icon: "hero-home"},
        %{label: "Contacts", path: "/crm/contacts", icon: "hero-user-group"},
        %{label: "Deals", path: "/crm/deals", icon: "hero-currency-dollar"},
        %{label: "Activities", path: "/crm/activities", icon: "hero-clock"}
      ]
    }
  end
  
  # Delegate to internal contexts
  defdelegate list_contacts(opts \\ []), to: Contacts
  defdelegate get_contact!(id), to: Contacts
  # ... more delegations
end
```

## 5. Sistema White-Label

O sistema de white-label permite personalização completa por tenant:

```elixir
typed_schema "themes" do
  field :primary_color, :string, default: "#6366f1"
  field :secondary_color, :string, default: "#10b981"
  field :accent_color, :string, default: "#f43f5e"
  field :background_color, :string, default: "#ffffff"
  field :text_color, :string, default: "#111827"
  
  field :font_family, :string, default: "system-ui"
  field :heading_font, :string
  
  field :logo_url, :string
  field :favicon_url, :string
  field :login_background_url, :string
  
  field :custom_css, :string
  field :custom_js, :string
  
  field :company_name, :string
  field :support_email, :string
  field :copyright_text, :string
  
  belongs_to :tenant, PetalPro.MultiTenant.Tenant
  
  timestamps()
end
```

O tema é aplicado dinamicamente nos layouts:

```elixir
# Theme provider component
def theme_css(assigns) do
  ~H"""
  <style>
    :root {
      --color-primary: <%= @theme.primary_color %>;
      --color-secondary: <%= @theme.secondary_color %>;
      --color-accent: <%= @theme.accent_color %>;
      --color-background: <%= @theme.background_color %>;
      --color-text: <%= @theme.text_color %>;
      --font-family: <%= @theme.font_family %>;
      --font-heading: <%= @theme.heading_font || @theme.font_family %>;
    }
    
    <%= if @theme.custom_css do %>
      <%= raw(@theme.custom_css) %>
    <% end %>
  </style>
  """
end
```

## 6. Diretrizes de Desenvolvimento

### 6.1 Uso Obrigatório de Generators

**TODOS os novos recursos devem ser criados usando os generators do Petal Pro**. Isso garante consistência e conformidade com os padrões do framework.

```bash
# Criando um contexto para um módulo
mix petal.gen.context AppModules.CRM.Contacts Contact contacts \
  name:string \
  email:string:unique \
  phone:string \
  tenant_id:references:tenants

# Criando a interface LiveView
mix petal.gen.live AppModules.CRM.Contacts Contact contacts \
  name:string \
  email:string \
  phone:string \
  tenant_id:references:tenants
```

### 6.2 Padrão de Diretórios e Arquivos

Seguir estritamente a estrutura de diretórios do Petal Pro:

```
# Para contextos e módulos
lib/petal_pro/app_modules/module_name/
├── module_name.ex            # API pública do módulo
├── entity.ex                 # Schema principal
├── entity_query.ex           # Funções de query composicionais
└── contexts/                 # Sub-contextos específicos

# Para interfaces LiveView
lib/petal_pro_web/live/modules/module_name/
├── index.ex                  # LiveView principal
├── index.html.heex           # Template principal
└── components/               # Componentes específicos do módulo
```

### 6.3 Background Jobs e Tarefas Assíncronas

Usar o padrão do Petal Pro para tarefas assíncronas, via Oban:

```elixir
defmodule PetalPro.AppModules.CRM.Workers.ContactSyncWorker do
  use Oban.Worker, queue: :default, unique: [period: 5]
  
  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"tenant_id" => tenant_id}}) do
    # Synchronization logic
    :ok
  end
end

# Usage
%{tenant_id: tenant.id}
|> PetalPro.AppModules.CRM.Workers.ContactSyncWorker.new()
|> Oban.insert()
```

### 6.4 LiveViews e Componentes

Seguir os padrões de LiveView do Petal Pro, incluindo os componentes padronizados:

```elixir
defmodule PetalProWeb.Modules.CRM.ContactsLive.Index do
  use PetalProWeb, :live_view
  
  alias PetalPro.AppModules.CRM
  alias PetalProWeb.DataTable
  
  @data_table_opts [
    default_limit: 50,
    default_order: %{order_by: [:name], order_directions: [:asc]},
    filterable: [:id, :name, :email],
    sortable: [:id, :name, :email, :inserted_at]
  ]
  
  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end
  
  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end
  
  # Standard LiveView pattern as generated by Petal Pro
end
```

## 7. Fluxo de Trabalho para Novos Módulos

1. **Planejamento**: Definir estrutura de dados e casos de uso do módulo
2. **Generators**: Utilizar os generators para criar contextos e schemas base
3. **Behaviour**: Implementar o comportamento `PetalPro.Modules.Behaviours.Module`
4. **Interfaces**: Criar as interfaces LiveView usando generators
5. **Registro**: Registrar o módulo no sistema de módulos
6. **Testes**: Implementar testes automatizados para o módulo

## 8. Integração com Recursos Existentes

O Petal Pro inclui vários recursos prontos que devem ser aproveitados:

- **Sistema de Autenticação**: Completo com login, registro, recuperação de senha
- **Organizações**: Multitenancy em nível de organização
- **Subscriptions**: Integração com Stripe para cobrança
- **Administração**: Dashboard para administradores
- **Blog/CMS**: Sistema de blog com editor WYSIWYG

## 9. Deployment e Configuração

Seguir as diretrizes de deployment do Petal Pro:

```elixir
# config/runtime.exs
config :petal_pro, :multi_tenant,
  enabled: System.get_env("MULTI_TENANT_ENABLED", "true") == "true",
  schema_prefix: System.get_env("TENANT_SCHEMA_PREFIX", "tenant_"),
  create_tenant_schemas: System.get_env("CREATE_TENANT_SCHEMAS", "true") == "true"

config :triplex,
  repo: PetalPro.Repo,
  reserved_tenants: ["public", "www", "admin", "master"],
  tenant_prefix: System.get_env("TENANT_SCHEMA_PREFIX", "tenant_")
```

## 10. Conclusão

Este projeto estende a base do Petal Pro com funcionalidades multi-tenant avançadas. É **crucial** seguir os padrões, convenções e utilizar os generators do framework para manter a consistência e qualidade do código. A arquitetura modular permite a adição de novos módulos de forma isolada, garantindo flexibilidade e escalabilidade.

Todo desenvolvimento deve seguir os princípios de Clean Architecture e as convenções do Petal Pro para garantir um sistema coeso, manutenível e escalável.

## 11. Estratégia de Migração de Dados Multi-Tenant

A migração de dados em um ambiente multi-tenant com esquemas PostgreSQL isolados requer uma abordagem específica. O Petal Pro Multi-Tenant estende o sistema de migrações do Ecto utilizando o Triplex:

```elixir
defmodule PetalPro.MultiTenant.Migrations do
  @moduledoc """
  Handles tenant-specific migrations across isolated PostgreSQL schemas.
  """
  
  alias PetalPro.MultiTenant.Tenants
  alias Triplex.Migrations, as: TrplxMigrations
  
  @doc """
  Runs module-specific migrations for a single tenant.
  """
  def run_tenant_migrations(tenant, module_code) do
    # Get migration paths from module registry
    migration_paths = get_module_migration_paths(module_code)
    
    # Run migrations on tenant schema
    Triplex.migrate(tenant.schema_prefix, migration_paths)
  end
  
  @doc """
  Runs migrations across all tenants.
  """
  def run_all_tenant_migrations do
    Tenants.list_tenants(isolation_type: :isolated)
    |> Enum.each(fn tenant ->
      tenant.module_subscriptions
      |> Enum.each(fn subscription ->
        run_tenant_migrations(tenant, subscription.module_code)
      end)
    end)
  end
end
```

### Mix Tasks para Migrações

Utilize as mix tasks customizadas para gerenciar migrações em ambiente multi-tenant:

```bash
# Gerar migração para um módulo específico
mix tenant.gen.migration create_contacts_table --module=crm

# Executar migrações para todos os tenants
mix tenant.migrate

# Executar migrações para um tenant específico
mix tenant.migrate --tenant=tenant-slug
```

## 12. Estratégia de Estado e Comunicação em Tempo Real

### 12.1 PubSub para Comunicação Cross-Tenant

A arquitetura utiliza Phoenix PubSub para comunicação entre módulos e tenants:

```elixir
defmodule PetalPro.Modules.PubSub do
  @moduledoc """
  Centralized PubSub interface for cross-module and cross-tenant communication.
  """
  
  alias Phoenix.PubSub
  
  @pubsub PetalPro.PubSub
  
  @doc """
  Broadcasts a tenant-specific event.
  """
  def broadcast_tenant_event(tenant_id, module_code, event_name, payload) do
    topic = tenant_topic(tenant_id, module_code)
    PubSub.broadcast(@pubsub, topic, {event_name, payload})
  end
  
  @doc """
  Subscribes to tenant-specific events.
  """
  def subscribe_to_tenant_events(tenant_id, module_code) do
    topic = tenant_topic(tenant_id, module_code)
    PubSub.subscribe(@pubsub, topic)
  end
  
  defp tenant_topic(tenant_id, module_code) do
    "tenant:#{tenant_id}:module:#{module_code}"
  end
end
```

### 12.2 Padrão para Presence

Implementação de Presence para rastreamento de usuários online por tenant:

```elixir
defmodule PetalProWeb.TenantPresence do
  @moduledoc """
  Tracks user presence on a per-tenant basis.
  """
  use Phoenix.Presence, otp_app: :petal_pro,
                        pubsub_server: PetalPro.PubSub
                        
  def track_user(tenant_id, user_id, meta \\ %{}) do
    topic = "tenant_presence:#{tenant_id}"
    meta = Map.merge(%{online_at: DateTime.utc_now()}, meta)
    
    track(self(), topic, user_id, meta)
  end
  
  def list_users_in_tenant(tenant_id) do
    topic = "tenant_presence:#{tenant_id}"
    list(topic)
  end
end
```

## 13. Segurança e Controle de Acesso

### 13.1 Modelo de Autorização Multi-Nível

A arquitetura implementa um sistema de autorização em múltiplos níveis:

```elixir
defmodule PetalPro.Authorization do
  @moduledoc """
  Multi-layered authorization system with tenant, module, and resource policies.
  """
  
  alias PetalPro.MultiTenant.Tenants
  alias PetalPro.Modules
  
  @doc """
  Authorization flow:
  1. Tenant access check
  2. Module subscription check
  3. Module-specific permission check
  4. Resource-level permission check
  """
  def authorize(user, action, resource, opts \\ []) do
    tenant_id = opts[:tenant_id] || infer_tenant_id(resource)
    module_code = opts[:module_code] || infer_module_code(resource)
    
    with :ok <- check_tenant_access(user, tenant_id),
         :ok <- check_module_access(tenant_id, module_code),
         :ok <- check_module_permission(user, tenant_id, module_code, action),
         :ok <- check_resource_permission(user, action, resource, tenant_id) do
      :ok
    else
      {:error, reason} -> {:error, reason}
    end
  end
  
  # Individual check implementations
  defp check_tenant_access(user, tenant_id) do
    # Check if user has access to tenant
  end
  
  defp check_module_access(tenant_id, module_code) do
    # Check if tenant has access to module
  end
  
  defp check_module_permission(user, tenant_id, module_code, action) do
    # Check user's module-specific permissions
  end
  
  defp check_resource_permission(user, action, resource, tenant_id) do
    # Check resource-level permissions
  end
  
  # Helper functions to infer tenant_id and module_code from resource
  defp infer_tenant_id(resource) do
    # Logic to determine tenant_id from resource
  end
  
  defp infer_module_code(resource) do
    # Logic to determine module_code from resource
  end
end
```

## 14. Extensibilidade e Hooks

### 14.1 Sistema de Hooks para Extensão

Uma arquitetura de hooks permite estender o comportamento sem modificar o código base:

```elixir
defmodule PetalPro.Modules.HookSystem do
  @moduledoc """
  Hook system allowing modules to extend core functionality.
  """
  
  @hooks_registry %{}
  
  def register_hook(module_code, hook_point, callback) when is_function(callback, 1) do
    hook_key = {module_code, hook_point}
    existing_callbacks = Map.get(@hooks_registry, hook_key, [])
    @hooks_registry = Map.put(@hooks_registry, hook_key, [callback | existing_callbacks])
    :ok
  end
  
  def execute_hooks(hook_point, data, opts \\ []) do
    tenant_id = opts[:tenant_id]
    
    # Get all registered modules for tenant
    modules = if tenant_id do
      Modules.list_tenant_modules(tenant_id)
    else
      Modules.list_all_modules()
    end
    
    # Execute hooks for each relevant module
    Enum.reduce(modules, data, fn module, acc ->
      hooks = Map.get(@hooks_registry, {module.code, hook_point}, [])
      Enum.reduce(hooks, acc, fn hook, inner_acc ->
        hook.(inner_acc)
      end)
    end)
  end
end
```

### 14.2 Hook Points no Ciclo de Vida do Tenant

```elixir
# Example of hook registration in a module
defmodule PetalPro.AppModules.CRM do
  alias PetalPro.Modules.HookSystem
  
  def register_hooks do
    HookSystem.register_hook("crm", :tenant_created, &handle_tenant_created/1)
    HookSystem.register_hook("crm", :user_created, &handle_user_created/1)
    HookSystem.register_hook("crm", :dashboard_widgets, &provide_dashboard_widgets/1)
  end
  
  defp handle_tenant_created(%{tenant: tenant} = data) do
    # Initialize CRM data for new tenant
    data
  end
  
  defp handle_user_created(%{user: user, tenant: tenant} = data) do
    # Setup CRM permissions for new user
    data
  end
  
  defp provide_dashboard_widgets(widgets) do
    [
      %{name: "recent_contacts", component: PetalProWeb.CRM.Components.RecentContactsWidget},
      %{name: "deals_funnel", component: PetalProWeb.CRM.Components.DealsFunnelWidget} 
      | widgets
    ]
  end
end
```

## 15. Padrões para Desenvolvimento de Novos Módulos

### 15.1 Generator Customizado para Módulos

Utilize o generator customizado para módulos do Petal Pro Multi-Tenant:

```bash
# Criar um novo módulo aplicativo
mix petal.gen.module Helpdesk \
  --code=helpdesk \
  --description="Customer support and ticket management system"
```

Isso gera automaticamente:
- Estrutura de diretórios do módulo
- Implementação base do comportamento `Module`
- Arquivos de configuração e rotas
- Testes do módulo

### 15.2 Implementação de Módulo Conforme Padrão

Todos os módulos devem implementar uma API pública clara e consistente:

```elixir
defmodule PetalPro.AppModules.Helpdesk do
  @moduledoc """
  Helpdesk module for customer support ticket management.
  """
  @behaviour PetalPro.Modules.Behaviours.Module
  
  # Public API - delegate to internal contexts
  alias PetalPro.AppModules.Helpdesk.{Tickets, Agents, Teams}
  
  # Module behaviour implementations
  @impl true
  def code, do: "helpdesk"
  
  @impl true
  def name, do: "Helpdesk"
  
  # Other behaviour implementation...
  
  # Public API
  defdelegate list_tickets(opts \\ []), to: Tickets
  defdelegate get_ticket!(id), to: Tickets
  defdelegate create_ticket(attrs), to: Tickets
  defdelegate update_ticket(ticket, attrs), to: Tickets
  defdelegate delete_ticket(ticket), to: Tickets
  
  # More public functions delegated to internal contexts...
end
```

O estrito seguimento desses padrões, combinado com o uso obrigatório dos generators do Petal Pro, garante consistência, manutenibilidade e um desenvolvimento ágil de novos recursos na plataforma multi-tenant.