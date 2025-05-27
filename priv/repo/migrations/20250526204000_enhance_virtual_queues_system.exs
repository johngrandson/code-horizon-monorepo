defmodule PetalPro.Repo.Migrations.EnhanceVirtualQueuesSystem do
  use Ecto.Migration

  @moduledoc """
  Enhancement migration for Virtual Queues system.

  This migration would be run after the initial system is deployed
  to add new features like:
  - Queue categories and types
  - Service level agreements (SLA)
  - Integration with user accounts
  - Enhanced reporting fields
  """

  def up do
    # Add new fields to queues table
    alter table(:virtual_queues_queues) do
      # Queue categorization and configuration
      add :category, :string, default: "general"
      add :queue_type, :string, default: "standard"
      # Default blue color
      add :color_code, :string, default: "#3B82F6"

      # SLA and service level configuration
      add :expected_wait_time_minutes, :integer
      add :max_wait_time_minutes, :integer
      add :auto_close_after_minutes, :integer

      # Integration with user accounts (optional assignment to specific users/agents)
      add :assigned_user_id, references(:users, on_delete: :nilify_all)

      # Advanced configuration
      add :allow_online_checkin, :boolean, default: false
      add :require_customer_info, :boolean, default: false
      add :send_sms_notifications, :boolean, default: false

      # Reporting and analytics fields
      add :total_tickets_served, :integer, default: 0
      add :average_service_time_seconds, :integer
      add :last_analytics_update, :utc_datetime
    end

    # Add new fields to tickets table
    alter table(:virtual_queues_tickets) do
      # Enhanced customer information
      add :customer_id, references(:users, on_delete: :nilify_all)
      add :estimated_wait_time_minutes, :integer
      add :actual_wait_time_minutes, :integer
      add :service_time_seconds, :integer

      # Communication and notifications
      add :sms_sent, :boolean, default: false
      add :email_sent, :boolean, default: false
      add :notification_preferences, :map, default: %{}

      # Enhanced tracking
      # kiosk, online, mobile, etc.
      add :check_in_method, :string, default: "kiosk"
      add :assigned_agent_id, references(:users, on_delete: :nilify_all)

      # Quality and feedback
      add :customer_rating, :integer
      add :customer_feedback, :text
      add :internal_notes, :text

      # SLA tracking
      add :sla_missed, :boolean, default: false
      add :sla_target_time, :utc_datetime
    end

    # Create new supporting tables

    # Queue templates for quick queue setup
    create table(:virtual_queues_templates) do
      add :name, :string, null: false
      add :description, :text
      add :queue_settings, :map, null: false, default: %{}
      add :is_system_template, :boolean, default: false
      add :created_by_user_id, references(:users, on_delete: :nilify_all)

      timestamps()
    end

    # Queue operating hours
    create table(:virtual_queues_operating_hours) do
      add :queue_id, references(:virtual_queues_queues, on_delete: :delete_all), null: false
      # 0-6, Sunday = 0
      add :day_of_week, :integer, null: false
      add :start_time, :time, null: false
      add :end_time, :time, null: false
      add :is_closed, :boolean, default: false

      timestamps()
    end

    # Queue announcements/messages
    create table(:virtual_queues_announcements) do
      add :queue_id, references(:virtual_queues_queues, on_delete: :delete_all), null: false
      add :title, :string, null: false
      add :message, :text, null: false
      # info, warning, success, error
      add :announcement_type, :string, default: "info"
      add :is_active, :boolean, default: true
      add :start_date, :utc_datetime
      add :end_date, :utc_datetime
      add :created_by_user_id, references(:users, on_delete: :nilify_all)

      timestamps()
    end

    # Add indexes for new fields
    create index(:virtual_queues_queues, [:category])
    create index(:virtual_queues_queues, [:queue_type])
    create index(:virtual_queues_queues, [:assigned_user_id])

    create index(:virtual_queues_tickets, [:customer_id])
    create index(:virtual_queues_tickets, [:assigned_agent_id])
    create index(:virtual_queues_tickets, [:check_in_method])
    create index(:virtual_queues_tickets, [:sla_missed])

    create index(:virtual_queues_operating_hours, [:queue_id, :day_of_week])
    create index(:virtual_queues_announcements, [:queue_id, :is_active])

    # Add unique constraints
    create unique_index(
             :virtual_queues_operating_hours,
             [:queue_id, :day_of_week],
             name: :virtual_queues_operating_hours_unique_day
           )

    # Add check constraints for new fields
    create constraint(:virtual_queues_queues, :valid_category,
             check:
               "category IN ('general', 'customer_service', 'technical_support', 'billing', 'other')"
           )

    create constraint(:virtual_queues_queues, :valid_queue_type,
             check: "queue_type IN ('standard', 'priority', 'appointment', 'walk_in')"
           )

    create constraint(:virtual_queues_queues, :valid_color_code,
             check: "color_code ~ '^#[0-9A-Fa-f]{6}$'"
           )

    create constraint(:virtual_queues_tickets, :valid_rating,
             check: "customer_rating IS NULL OR (customer_rating >= 1 AND customer_rating <= 5)"
           )

    create constraint(:virtual_queues_tickets, :valid_check_in_method,
             check: "check_in_method IN ('kiosk', 'online', 'mobile', 'agent', 'phone')"
           )

    create constraint(:virtual_queues_operating_hours, :valid_day_of_week,
             check: "day_of_week >= 0 AND day_of_week <= 6"
           )

    create constraint(:virtual_queues_operating_hours, :valid_time_range,
             check: "start_time < end_time OR is_closed = true"
           )

    # Create a function to automatically calculate service times
    execute """
    CREATE OR REPLACE FUNCTION calculate_ticket_service_time()
    RETURNS TRIGGER AS $$
    BEGIN
      -- Calculate actual wait time when ticket is called
      IF NEW.status = 'called' AND OLD.status = 'waiting' AND NEW.called_at IS NOT NULL THEN
        NEW.actual_wait_time_minutes := EXTRACT(EPOCH FROM (NEW.called_at - NEW.inserted_at)) / 60;
      END IF;

      -- Calculate service time when ticket is completed
      IF NEW.status = 'completed' AND NEW.served_at IS NOT NULL AND NEW.completed_at IS NOT NULL THEN
        NEW.service_time_seconds := EXTRACT(EPOCH FROM (NEW.completed_at - NEW.served_at));
      END IF;

      RETURN NEW;
    END;
    $$ LANGUAGE plpgsql;
    """

    # Create trigger to automatically calculate service times
    execute """
    CREATE TRIGGER calculate_service_time_trigger
      BEFORE UPDATE ON virtual_queues_tickets
      FOR EACH ROW
      EXECUTE FUNCTION calculate_ticket_service_time();
    """
  end

  def down do
    # Drop the trigger and function
    execute "DROP TRIGGER IF EXISTS calculate_service_time_trigger ON virtual_queues_tickets"
    execute "DROP FUNCTION IF EXISTS calculate_ticket_service_time()"

    # Drop supporting tables
    drop_if_exists table(:virtual_queues_announcements)
    drop_if_exists table(:virtual_queues_operating_hours)
    drop_if_exists table(:virtual_queues_templates)

    # Remove added columns from tickets table
    alter table(:virtual_queues_tickets) do
      remove_if_exists :customer_id, references(:users)
      remove_if_exists :estimated_wait_time_minutes, :integer
      remove_if_exists :actual_wait_time_minutes, :integer
      remove_if_exists :service_time_seconds, :integer
      remove_if_exists :sms_sent, :boolean
      remove_if_exists :email_sent, :boolean
      remove_if_exists :notification_preferences, :map
      remove_if_exists :check_in_method, :string
      remove_if_exists :assigned_agent_id, references(:users)
      remove_if_exists :customer_rating, :integer
      remove_if_exists :customer_feedback, :text
      remove_if_exists :internal_notes, :text
      remove_if_exists :sla_missed, :boolean
      remove_if_exists :sla_target_time, :utc_datetime
    end

    # Remove added columns from queues table
    alter table(:virtual_queues_queues) do
      remove_if_exists :category, :string
      remove_if_exists :queue_type, :string
      remove_if_exists :color_code, :string
      remove_if_exists :expected_wait_time_minutes, :integer
      remove_if_exists :max_wait_time_minutes, :integer
      remove_if_exists :auto_close_after_minutes, :integer
      remove_if_exists :assigned_user_id, references(:users)
      remove_if_exists :allow_online_checkin, :boolean
      remove_if_exists :require_customer_info, :boolean
      remove_if_exists :send_sms_notifications, :boolean
      remove_if_exists :total_tickets_served, :integer
      remove_if_exists :average_service_time_seconds, :integer
      remove_if_exists :last_analytics_update, :utc_datetime
    end
  end
end
