<p align="center">
  <img src="https://shy-cloud-1717.t3.storage.dev/logo_for_emails.png" height="128">

  <p align="center">
    Enterprise Multi-Tenant Platform with White-Label capabilities built using PETAL Stack (Phoenix, Elixir, Tailwind CSS, Alpine.js and LiveView).
  </p>
</p>

<p align="center">
  <a href="https://docs.petal.build">DOCS</a>
</p>

## ✨ Features

### Authentication & Authorization
- 🔐 Email/Password authentication with secure password hashing
- 🌐 Social logins via Google and GitHub OAuth
- 🔑 Two-Factor Authentication (2FA) support
- 🔄 Session management and secure token handling

### Organization & Team Management
- 👥 Create and manage multiple organizations
- 👥 Invite team members with role-based access control
- 🔄 Real-time team collaboration features
- 🏢 Organization-wide settings and customization

### Billing & Subscriptions
- 💳 Stripe integration for payments
- 🔄 Recurring subscription management
- 📊 Usage-based billing
- 📝 Invoice generation and history
- 💰 Multiple payment methods

### Email System
- ✉️ Transactional emails with responsive templates
- 📧 Email verification and password reset flows
- 🔔 Notification preferences
- 📤 SMTP configuration with multiple providers

### Admin Dashboard
- 📊 System metrics and analytics
- 👥 User and organization management
- ⚙️ System configuration
- 📈 Usage statistics

### Developer Experience
- 🚀 Hot code reloading
- 📝 Comprehensive API documentation
- 🔍 Search functionality
- 📱 Responsive design with Tailwind CSS
- ⚡ Real-time updates with Phoenix LiveView
- 🚦 Background job processing with Oban

## 🛠️ Built With

### Backend
- **Elixir** (1.17+)
- **Phoenix** (1.7+) - Web framework
- **Ecto** - Database wrapper and query generator
- **PostgreSQL** - Primary database
- **Oban** - Background job processing

### Frontend
- **Phoenix LiveView** - Real-time, server-rendered UI
- **Tailwind CSS** - Utility-first CSS framework
- **Alpine.js** - Minimal framework for JavaScript behavior
- **ESBuild** - JavaScript bundler

### DevOps
- **Docker** - Containerization
- **GitHub Actions** - CI/CD
- **Sentry** - Error tracking
- **Prometheus** - Monitoring

### APIs & Integrations
- **Stripe** - Payments and subscriptions
- **OAuth 2.0** - Social logins (Google, GitHub)
- **SMTP** - Email delivery

## Get up and running

### Prerequisites

- **Elixir** (1.17 or later)
- **Erlang/OTP** (24.0 or later)
- **Node.js** (16.0 or later)
- **PostgreSQL** (13.0 or later)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/petal-pro.git
   cd petal-pro
   ```

2. **Install Elixir dependencies**
   ```bash
   mix deps.get
   ```

3. **Install Node.js dependencies**
   ```bash
   cd assets
   npm install
   cd ..
   ```

4. **Set up the database**
   ```bash
   mix ecto.create
   mix ecto.migrate
   ```

5. **Start the Phoenix server**
   ```bash
   mix phx.server
   ```

6. **Access the application**
   Visit [`http://localhost:4000`](http://localhost:4000) in your browser.

### Using Docker for Development

If you prefer to use Docker, you can start the application with:

```bash
docker-compose up -d
```

This will start:
- PostgreSQL 15.7
- The Phoenix application with hot-reload enabled

### Environment Variables

Create a `.env` file in the root directory with the following variables:

```env
# Database
DATABASE_URL=postgres://postgres:postgres@localhost:5432/petal_pro_dev

# Phoenix
SECRET_KEY_BASE=your_secret_key_base
LIVE_VIEW_SIGNING_SALT=your_signing_salt

# Email (for development)
SMTP_RELAY=smtp.mailtrap.io
SMTP_USERNAME=your_username
SMTP_PASSWORD=your_password
SMTP_PORT=2525
```

Generate a secure `SECRET_KEY_BASE` with:
```bash
mix phx.gen.secret
```

## Project Structure

The application follows a standard Phoenix 1.7+ structure with additional context modules:

```
lib/
├── petal_pro/                # Core business logic
│   ├── accounts/             # User authentication and profiles
│   ├── billing/              # Billing and subscriptions
│   │   ├── customers/        # Customer management
│   │   ├── providers/        # Payment providers (Stripe)
│   │   └── subscriptions/    # Subscription management
│   │
│   ├── logs/               # Application logging
│   ├── modules/              # Feature modules
│   │   └── behaviours/       # Module behaviors
│   │
│   ├── notifications/      # Notification system
│   ├── orgs/                 # Organization management
│   ├── posts/                # Blog/Content management
│   ├── settings/             # Application settings
│   └── white_label/          # White-label theming
│
└── petal_pro_web/           # Web interface
    ├── channels/            # WebSocket channels
    ├── components/          # UI components
    ├── controllers/         # HTTP controllers
    ├── live/                # LiveView modules
    │   ├── admin/          # Admin dashboard
    │   ├── billing/        # Billing interfaces
    │   └── user_settings/  # User settings
    └── router.ex           # Application routes
```

## Key Components

### User Authentication

- Email/password authentication
- Social logins (Google, GitHub)
- Two-factor authentication (2FA) with TOTP
- Password reset flow
- Account confirmation

### Organization Management

- Create and manage organizations
- Invite team members
- Role-based access control
- Organization settings

### Billing & Subscriptions

- Stripe integration for payments
- Subscription management
- Invoices and receipts
- Usage tracking

### Email System

- Responsive email templates
- SMTP configuration
- Email verification
- Notification preferences

## 🛠 Development

### Prerequisites

- Elixir 1.17+ and Erlang/OTP 24+
- Node.js 16+ and npm
- PostgreSQL 13+
- Git

### First-Time Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/petal-pro.git
   cd petal-pro
   ```

2. **Set up environment variables**
   ```bash
   cp .env.example .env
   # Edit .env with your configuration
   ```

3. **Install dependencies**
   ```bash
   # Install Elixir dependencies
   mix deps.get
   
   # Install Node.js dependencies
   cd assets && npm install && cd ..
   ```

4. **Set up the database**
   ```bash
   # Create and migrate the database
   mix ecto.setup
   
   # Or run these commands individually
   # mix ecto.create
   # mix ecto.migrate
   # mix run priv/repo/seeds.exs
   ```

5. **Start the development server**
   ```bash
   # Start Phoenix endpoint with IEx console
   iex -S mix phx.server
   ```

   Now you can visit [`localhost:4000`](http://localhost:4000) in your browser.

### Running Tests

```bash
# Run all tests
mix test

# Run tests for a specific file
mix test test/path/to/test_file.exs

# Run a specific test
mix test test/path/to/test_file.exs:123
```

### Code Quality

We use several tools to maintain code quality:

```bash
# Format code
mix format

# Static code analysis
mix credo --strict

# Type checking
mix dialyzer

# Security audit
mix sobelow
```

### Development Tips

- **Interactive Console**: Use `iex -S mix` for an interactive Elixir console
- **Code Reloading**: The Phoenix development server supports automatic code reloading
- **Database Console**: Access the database console with `psql -d petal_pro_dev`
- **View Logs**: Check logs in the terminal where the server is running

## ⚙️ Configuration

### Environment Variables

Create a `.env` file in the root directory with the following variables:

```env
# Application
MIX_ENV=dev
PORT=4000
SECRET_KEY_BASE=your_secret_key_base
LIVE_VIEW_SIGNING_SALT=your_signing_salt

# Database
DATABASE_URL=postgres://postgres:postgres@localhost:5432/petal_pro_dev
POOL_SIZE=10

# Email (for development)
SMTP_RELAY=smtp.mailtrap.io
SMTP_USERNAME=your_username
SMTP_PASSWORD=your_password
SMTP_PORT=2525
SMTP_FROM_EMAIL=no-reply@example.com

# OAuth (optional)
GOOGLE_CLIENT_ID=your_google_client_id
GOOGLE_CLIENT_SECRET=your_google_client_secret
GITHUB_CLIENT_ID=your_github_client_id
GITHUB_CLIENT_SECRET=your_github_client_secret

# Stripe (for billing)
STRIPE_SECRET_KEY=your_stripe_secret_key
STRIPE_PUBLISHABLE_KEY=your_stripe_publishable_key
STRIPE_WEBHOOK_SECRET=your_stripe_webhook_secret
```

### Generating Secrets

Generate a secure `SECRET_KEY_BASE` and `LIVE_VIEW_SIGNING_SALT`:

```bash
# Generate SECRET_KEY_BASE
mix phx.gen.secret

# Generate LIVE_VIEW_SIGNING_SALT
mix phx.gen.secret 32
```

### Database Configuration

The application uses PostgreSQL as the primary database. You can configure the connection in `config/dev.exs` or via environment variables:

```elixir
# config/dev.exs
config :petal_pro, PetalPro.Repo,
  username: "postgres",
  password: "postgres",
  database: "petal_pro_dev",
  hostname: "localhost",
  show_sensitive_data_on_connection_error: true,
  pool_size: 10
```

### Email Configuration

For development, you can use Mailtrap or a similar service. In production, configure your SMTP settings:

```elixir
# config/prod.exs
config :petal_pro, PetalPro.Mailer,
  adapter: Swoosh.Adapters.SMTP,
  relay: System.get_env("SMTP_RELAY"),
  username: System.get_env("SMTP_USERNAME"),
  password: System.get_env("SMTP_PASSWORD"),
  port: System.get_env("SMTP_PORT"),
  tls: :always,
  auth: :always,
  ssl: false,
  retries: 1,
  no_mx_lookups: false
```
# 🚀 Deployment

## Production Deployment

The application is designed to be deployed using Elixir releases. Here's how to deploy to a production environment:

### Prerequisites

- Elixir 1.17+ and Erlang/OTP 24+
- Node.js 16+
- PostgreSQL 13+
- A server with at least 1GB RAM (2GB recommended)

### Build the Release

1. Set the required environment variables in your production environment:
   ```bash
   # Required
   export MIX_ENV=prod
   export SECRET_KEY_BASE=$(mix phx.gen.secret)
   export DATABASE_URL=postgres://user:password@localhost/petal_pro_prod
   
   # Optional but recommended
   export PORT=4000
   export POOL_SIZE=15
   ```

2. Install dependencies and build the release:
   ```bash
   # Install Elixir dependencies
   mix deps.get --only prod
   
   # Install Node.js dependencies
   cd assets && npm install --progress=false --no-audit --loglevel=error && cd ..
   
   # Build assets
   npm run deploy --prefix ./assets
   
   # Compile and build the release
   mix phx.gen.release
   MIX_ENV=prod mix release
   ```

3. Run database migrations:
   ```bash
   _build/prod/rel/petal_pro/bin/petal_pro eval "PetalPro.Release.migrate"
   ```

4. Start the application:
   ```bash
   # Start the server in the foreground
   _build/prod/rel/petal_pro/bin/server
   
   # Or start as a daemon
   _build/prod/rel/petal_pro/bin/petal_pro daemon
   ```

### Systemd Service

For production deployments, it's recommended to use systemd to manage the application:

```ini
# /etc/systemd/system/petal_pro.service
[Unit]
Description=Petal Pro
After=network.target postgresql.service

[Service]
Type=simple
User=deploy
Group=deploy
EnvironmentFile=/path/to/env/file
WorkingDirectory=/path/to/application
ExecStart=/path/to/_build/prod/rel/petal_pro/bin/server
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
```

Then enable and start the service:

```bash
sudo systemctl enable petal_pro.service
sudo systemctl start petal_pro.service
```

### Environment Variables

Make sure to set these environment variables in production:

```bash
# Required
MIX_ENV=prod
SECRET_KEY_BASE=your_secret_key_base
DATABASE_URL=postgres://user:password@localhost/database_name

# Email (required for production)
SMTP_RELAY=smtp.sendgrid.net
SMTP_USERNAME=your_sendgrid_username
SMTP_PASSWORD=your_sendgrid_password
SMTP_PORT=587
SMTP_FROM_EMAIL=your-email@example.com

# OAuth (required if using social logins)
GOOGLE_CLIENT_ID=your_google_client_id
GOOGLE_CLIENT_SECRET=your_google_client_secret
GITHUB_CLIENT_ID=your_github_client_id
GITHUB_CLIENT_SECRET=your_github_client_secret

# Stripe (required for billing)
STRIPE_SECRET_KEY=your_stripe_secret_key
STRIPE_PUBLISHABLE_KEY=your_stripe_publishable_key
STRIPE_WEBHOOK_SECRET=your_stripe_webhook_secret
```

## Docker Deployment

You can also deploy using Docker:

1. Build the Docker image:
   ```bash
   docker build -t petal-pro:latest .
   ```

2. Run the container:
   ```bash
   docker run -d \
     --name petal-pro \
     -p 4000:4000 \
     -e DATABASE_URL=postgres://user:pass@host:5432/db \
     -e SECRET_KEY_BASE=your_secret_key_base \
     petal-pro:latest
   ```

## Monitoring

### Logs

View application logs:
```bash
# When running with systemd
journalctl -u petal_pro.service -f

# When running directly
_build/prod/rel/petal_pro/var/log/erlang.log.1
```

### Health Check

The application exposes a health check endpoint at `/api/health` that returns `200 OK` when the application is running.

## Scaling

### Database Connection Pool

Adjust the connection pool size based on your database capacity:

```bash
export POOL_SIZE=20  # Adjust based on your database capacity
```

### Web Server

For higher traffic, you can run multiple BEAM nodes behind a load balancer:

1. Update the `:http` configuration in `config/runtime.exs` to listen on all interfaces:
   ```elixir
   config :petal_pro, PetalProWeb.Endpoint,
     http: [ip: {0, 0, 0, 0}, port: 4000],
     # ... other config
   ```

2. Use a reverse proxy like Nginx or Caddy in front of your application.

## Backup and Recovery

### Database Backups

Set up regular database backups using `pg_dump`:

```bash
# Daily backup
0 3 * * * pg_dump -U postgres petal_pro_prod > /backups/petal_pro_$(date +\%Y\%m\%d).sql
```

### File Storage

If you're using local file storage, make sure to back up the `priv/static/uploads` directory.

## Security

- Keep your dependencies up to date with `mix deps.update --all`
- Use HTTPS in production
- Set secure cookie options in production
- Regularly rotate your `SECRET_KEY_BASE`
- Use strong database passwords
- Keep your server's operating system updated

# 📜 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.


## Acknowledgments

- [Phoenix Framework](https://www.phoenixframework.org/)
- [Tailwind CSS](https://tailwindcss.com/)
- [Alpine.js](https://alpinejs.dev/)
- [LiveView](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html)
