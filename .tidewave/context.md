# Documentação de Contexto: Petal Pro Platform

## 1. Visão Geral & Arquitetura

O projeto é uma plataforma white-label construída sobre o framework Petal Pro, que utiliza a stack PETAL (Phoenix, Elixir, TailwindCSS, Alpine.js, LiveView). A arquitetura segue os princípios de design da Clean Architecture e Domain-Driven Design, organizando o código em contextos bem definidos com interfaces claras, com foco em organizações como unidade central de isolamento de dados.

```
lib/
├── petal_pro/                # Core business logic
│   ├── accounts/             # User authentication and management
│   ├── orgs/                 # Organization context with memberships
│   ├── billing/              # Subscription management with Stripe
│   │   ├── modules/          # Module system
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
mix petal.gen.context Orgs Org orgs name:string slug:string:unique status:enum:active:inactive:suspended

# Criar um novo LiveView
mix petal.gen.live Orgs Org orgs name:string slug:string status:enum
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

  typed_schema "orgs" do
    field :name, :string
    field :slug, :string, unique: true
    field :status, Ecto.Enum, values: [:active, :inactive, :suspended]
    field :settings, :map, default: %{}
    
    has_many :members, PetalPro.Orgs.Member
    has_many :users, through: [:members, :user]
    
    timestamps()
  end
  
  def changeset(org, attrs) do
    org
    |> cast(attrs, [:name, :slug, :status, :settings])
    |> validate_required([:name, :slug, :status])
    |> unique_constraint(:slug)
  end
end

# Context pattern with standardized API
defmodule PetalPro.Orgs do
  import Ecto.Query
  alias PetalPro.Repo
  alias PetalPro.Orgs.Org
  
  # Standard CRUD functions
  def list_orgs(filters \\ []), do: Org |> apply_filters(filters) |> Repo.all()
  def get_org!(id), do: Repo.get!(Org, id)
  def create_org(attrs), do: %Org{} |> Org.changeset(attrs) |> Repo.insert()
  def update_org(%Org{} = org, attrs), do: org |> Org.changeset(attrs) |> Repo.update()
  def delete_org(%Org{} = org), do: Repo.delete(org)
  def change_org(%Org{} = org, attrs \\ %{}), do: Org.changeset(org, attrs)
end
```

## 3. Gerenciamento de Organizações

O projeto utiliza organizações (orgs) para gerenciar o escopo dos dados e permissões:

### 3.1 Estrutura de Organizações

Cada organização possui seus próprios dados e configurações:

```elixir
# Schema definition
typed_schema "orgs" do
  field :name, :string
  field :slug, :string, unique: true
  field :status, Ecto.Enum, values: [:active, :inactive, :suspended]
  field :settings, :map, default: %{}
  
  # Relationships
  has_many :members, PetalPro.Orgs.Member
  has_many :users, through: [:members, :user]
  has_one :theme, PetalPro.WhiteLabel.Theme
  has_many :app_module_subscriptions, PetalPro.AppModules.Subscription
  
  timestamps()
end
```

### 3.2 Autenticação e Autorização

O acesso aos dados é controlado através da organização atual do usuário:

```elixir
defmodule PetalProWeb.Plugs.RequireOrgAccess do
  import Plug.Conn
  import Phoenix.Controller, only: [put_flash: 3, redirect: 2]
  
  def init(opts), do: opts
  
  def call(conn, _opts) do
    current_user = conn.assigns.current_user
    org_id = get_org_id_from_conn(conn)
    
    if has_access?(current_user, org_id) do
      assign(conn, :current_org_id, org_id)
    else
      conn
      |> put_flash(:error, "You don't have access to this organization")
      |> redirect(to: "/orgs")
      |> halt()
    end
  end
  
  defp has_access?(user, org_id) do
    PetalPro.Orgs.user_in_org?(user, org_id)
  end
end
```

## 4. Sistema de Módulos

A arquitetura modular permite que funcionalidades sejam ativadas por organização, implementando o padrão de comportamento (behaviour):

```elixir
defmodule PetalPro.AppModules.Behaviours.AppModule do
  @callback code() :: String.t()
  @callback name() :: String.t() 
  @callback description() :: String.t()
  @callback version() :: String.t()
  @callback dependencies() :: [String.t()]
  
  @callback setup_org(org_id :: integer, opts :: keyword) :: :ok | {:error, term()}
  @callback cleanup_org(org_id :: integer) :: :ok | {:error, term()}
  
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

Cada módulo funcional deve seguir a implementação do comportamento, garantindo que os dados sejam sempre escopados à organização atual:

```elixir
# Example module implementation
defmodule PetalPro.AppModules.CRM do
  @behaviour PetalPro.AppModules.Behaviours.AppModule
  
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
  def setup_org(org_id, _opts \\ []) do
    # Initialize organization-specific data
    :ok
  end
  
  @impl true
  def cleanup_org(org_id) do
    # Clean up organization data
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

O sistema de white-label permite personalização completa por organização:

```elixir
typed_schema "themes" do
  field :primary_color, :string, default: "#6366f1"
  field :secondary_color, :string, default: "#10b981"
  field :accent_color, :string, default: "#f43f5e"
  field :background_color, :string, default: "#ffffff"
  field :text_color, :string, default: "#1f2937"
  field :font_family, :string, default: "sans-serif"
  field :logo_url, :string
  field :favicon_url, :string
  field :login_background_url, :string
  field :custom_css, :string
  field :custom_js, :string
  field :company_name, :string
  field :support_email, :string
  field :copyright_text, :string
  
  belongs_to :org, PetalPro.Orgs.Org
  
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
  org_id:references:orgs

# Criando a interface LiveView
mix petal.gen.live AppModules.CRM.Contacts Contact contacts \
  name:string \
  email:string \
  phone:string \
  org_id:references:orgs
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
  def perform(%Oban.Job{args: %{"org_id" => org_id}}) do
    # Synchronization logic
    :ok
  end
end

# Usage
%{org_id: org.id}
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
3. **Behaviour**: Implementar o comportamento `PetalPro.AppModules.Behaviours.AppModule`
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

## 10. Conclusão

Este projeto utiliza organizações para gerenciar o escopo dos dados e permissões. É **crucial** seguir os padrões, convenções e utilizar os generators do framework para manter a consistência e qualidade do código. A arquitetura modular permite a adição de novos módulos de forma isolada, garantindo flexibilidade e escalabilidade.

Todo desenvolvimento deve seguir os princípios de Clean Architecture e as convenções do Petal Pro para garantir um sistema coeso, manutenível e escalável.

## 11. Sistema de Eventos

O sistema de eventos do Petal Pro é responsável por gerenciar notificações em tempo real e comunicação entre diferentes partes da aplicação. A arquitetura é baseada no padrão Pub/Sub (Publicador/Assinante) do Phoenix.PubSub.

### 11.1 Estrutura do Módulo de Eventos

```
lib/petal_pro/events/
├── modules/
│   ├── notifications/      # Eventos de notificações do usuário
│   │   └── broadcaster.ex  # Lógica de broadcast de notificações
│   └── orgs/               # Eventos relacionados a organizações
│       ├── broadcaster.ex  # Lógica de broadcast de eventos de org
│       └── subscriber.ex   # Lógica de inscrição em eventos de org
```

### 11.2 Módulo de Notificações

O módulo `Notifications.Broadcaster` é responsável por gerenciar notificações em tempo real para os usuários:

```elixir
# Tópico de notificações para um usuário específico
PetalPro.Events.Modules.Notifications.Broadcaster.user_notifications_topic(user_id)

# Broadcast de atualização de notificações
PetalPro.Events.Modules.Notifications.Broadcaster.broadcast_user_notification(notification)
```

### 11.3 Eventos de Organização

O módulo `Orgs.Broadcaster` lida com eventos relacionados a organizações, como convites e alterações de membros:

#### Tipos de Eventos

1. **Convites**
   - `:invitation_sent` - Novo convite enviado
   - `:invitation_accepted` - Convite aceito
   - `:invitation_rejected` - Convite rejeitado
   - `:invitation_deleted` - Convite removido

2. **Membros**
   - `:invited_to_org` - Usuário convidado para uma organização
   - `:left_org` - Usuário saiu da organização

#### Exemplo de Uso

```elixir
# Enviar notificação de convite
PetalPro.Events.Modules.Orgs.Broadcaster.broadcast_invitation_sent(invitation, org)

# Notificar todos os membros de uma organização
PetalPro.Events.Modules.Orgs.Broadcaster.broadcast_to_org_members(org, :member_updated, %{user_id: user_id})
```

### 11.4 Sistema de Inscrição

O módulo `Orgs.Subscriber` gerencia as inscrições em eventos baseados no usuário e nas organizações às quais ele pertence:

```elixir
# Em um LiveView, registrar o assinante
@impl true
def mount(_params, _session, socket) do
  socket = PetalPro.Events.Modules.Orgs.Subscriber.register_subscriber(socket)
  {:ok, socket}
end

# Manipular eventos recebidos
@impl true
def handle_info({:invitation_sent, payload}, socket) do
  # Lógica para lidar com o evento
  {:noreply, socket}
end
```

### 11.5 Tópicos de Eventos

- `user:{user_id}:invitations` - Eventos de convite para um usuário específico
- `org:{org_id}:admin_notifications` - Notificações para administradores de uma organização
- `user:{user_id}:org:{org_id}` - Eventos específicos de organização para um usuário

## 12. Gerenciamento de Dados por Organização

O gerenciamento de dados é feito através de escopos de organização, onde cada organização possui seus próprios dados isolados. A migração de dados segue o padrão do Ecto, com as migrações sendo aplicadas ao banco de dados principal.

```elixir
defmodule PetalPro.ReleaseTasks.Migrate do
  @moduledoc """
  Task para executar migrações do banco de dados.
  Uso: `mix petal_pro.migrate`
  """
  use Task
  
  @migration_paths ["priv/repo/migrations"]
  
  def run(_args) do
    # Carrega a aplicação e suas dependências
    Application.ensure_all_started(:petal_pro)
    
    # Executa as migrações
    Ecto.Migrator.run(PetalPro.Repo, @migration_paths, :up, all: true)
  end
end

### Mix Tasks para Migrações

Utilize as mix tasks do Ecto para gerenciar migrações:

```bash
# Criar uma nova migração
mix ecto.gen.migration nome_da_migracao

# Executar migrações
mix ecto.migrate

# Reverter a última migração
mix ecto.rollback

A arquitetura utiliza Phoenix PubSub para comunicação em tempo real entre módulos e organizações:

```elixir
defmodule PetalPro.Events.PubSub do
  @moduledoc """
  Interface centralizada para comunicação entre módulos e organizações.
  """
  
  alias Phoenix.PubSub
  
  @pubsub PetalPro.PubSub
  
  @doc """
  Transmite um evento específico para uma organização.
  """
  def broadcast_org_event(org_id, module_code, event_name, payload) do
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
  
  alias PetalPro.Orgs.Org
  alias PetalPro.AppModules
  
  @doc """
  Authorization flow:
  1. Organization access check
  2. Module subscription check
  3. Module-specific permission check
  4. Resource-level permission check
  """
  def authorize(user, action, resource, opts \\ []) do
    org_id = opts[:org_id] || infer_org_id(resource)
    module_code = opts[:module_code] || infer_module_code(resource)
    
    with :ok <- check_org_access(user, org_id),
         :ok <- check_module_access(org_id, module_code),
         :ok <- check_module_permission(user, org_id, module_code, action),
         :ok <- check_resource_permission(user, action, resource, org_id) do
      :ok
    else
      {:error, reason} -> {:error, reason}
    end
  end
  
  # Individual check implementations
  defp check_org_access(user, org_id) do
    # Check if user has access to organization
  end
  
  defp check_module_access(org_id, module_code) do
    # Check if organization has access to module
  end
  
  defp check_module_permission(user, org_id, module_code, action) do
    # Check user's module-specific permissions
  end
  
  defp check_resource_permission(user, action, resource, org_id) do
    # Check resource-level permissions
  end
  
  # Helper functions to infer org_id and module_code from resource
  defp infer_org_id(resource) do
    # Logic to determine org_id from resource
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
defmodule PetalPro.AppModules.HookSystem do
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
  alias PetalPro.AppModules.HookSystem
  
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
  @behaviour PetalPro.AppModules.Behaviours.AppModule
  
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