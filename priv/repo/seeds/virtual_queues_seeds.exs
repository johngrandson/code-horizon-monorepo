# priv/repo/seeds/virtual_queues_seeds.exs
# Seeds for Virtual Queues system - run with: mix run priv/repo/seeds/virtual_queues_seeds.exs

alias PetalPro.AppModules.VirtualQueues.Queue
alias PetalPro.AppModules.VirtualQueues.Ticket
alias PetalPro.Orgs
alias PetalPro.Repo

require Logger

Logger.info("🎫 Seeding Virtual Queues system...")

# Get or create test organization
org =
  case Orgs.get_org("demo-org") do
    nil ->
      {:ok, org} =
        Orgs.create_org(%{
          name: "Demo Organization",
          slug: "demo-org"
        })

      org

    existing_org ->
      existing_org
  end

Logger.info("📊 Using organization: #{org.name}")

# Create sample queues
queues_data = [
  %{
    name: "Customer Service",
    description: "General customer service and support",
    status: :active,
    daily_reset: true,
    max_tickets_per_day: 100,
    org_id: org.id
  },
  %{
    name: "Technical Support",
    description: "Technical issues and troubleshooting",
    status: :active,
    daily_reset: false,
    max_tickets_per_day: 50,
    org_id: org.id
  },
  %{
    name: "Billing Department",
    description: "Billing inquiries and payment issues",
    status: :active,
    daily_reset: true,
    max_tickets_per_day: 75,
    org_id: org.id
  },
  %{
    name: "VIP Service",
    description: "Priority service for VIP customers",
    status: :active,
    daily_reset: false,
    max_tickets_per_day: 25,
    org_id: org.id
  },
  %{
    name: "Returns & Exchanges",
    description: "Product returns and exchanges",
    status: :paused,
    daily_reset: true,
    max_tickets_per_day: 40,
    org_id: org.id
  }
]

created_queues =
  Enum.map(queues_data, fn queue_attrs ->
    case Repo.get_by(Queue, name: queue_attrs.name, org_id: org.id) do
      nil ->
        %Queue{}
        |> Queue.create_changeset(queue_attrs)
        |> Repo.insert!()
        |> tap(fn queue -> Logger.info("✅ Created queue: #{queue.name}") end)

      existing_queue ->
        Logger.info("⏭️  Queue already exists: #{existing_queue.name}")
        existing_queue
    end
  end)

# Create sample tickets for active queues
active_queues = Enum.filter(created_queues, &(&1.status == :active))

# Sample customer names for realistic data
customer_names = [
  "John Smith",
  "Maria Garcia",
  "David Johnson",
  "Sarah Wilson",
  "Michael Brown",
  "Lisa Anderson",
  "Robert Taylor",
  "Jessica Martinez",
  "William Davis",
  "Ashley Miller",
  "Christopher Wilson",
  "Amanda Johnson",
  "Matthew Garcia",
  "Jennifer Brown",
  "Daniel Rodriguez",
  "Emily Davis",
  "Andrew Martinez",
  "Michelle Wilson",
  "Joshua Anderson",
  "Nicole Taylor"
]

# Sample service types
service_types = [
  "Account Issue",
  "Payment Problem",
  "Technical Support",
  "Product Return",
  "Billing Inquiry",
  "Service Upgrade",
  "General Question",
  "Complaint"
]

# Sample phone numbers (fake)
phone_numbers = [
  "+1 (555) 123-4567",
  "+1 (555) 234-5678",
  "+1 (555) 345-6789",
  "+1 (555) 456-7890",
  "+1 (555) 567-8901",
  "+1 (555) 678-9012"
]

# Create tickets for each active queue
Enum.each(active_queues, fn queue ->
  # Create 5-15 tickets per queue with various statuses
  ticket_count = Enum.random(5..15)

  Logger.info("🎫 Creating #{ticket_count} tickets for queue: #{queue.name}")

  # Generate tickets with realistic progression
  Enum.each(1..ticket_count, fn ticket_num ->
    customer_name = Enum.random(customer_names)
    service_type = Enum.random(service_types)
    phone = Enum.random(phone_numbers)

    # Determine status based on ticket number to simulate realistic progression
    status =
      cond do
        # First few tickets are completed
        ticket_num <= 3 -> :completed
        # A couple being served
        ticket_num <= 5 -> :serving
        # One called ticket
        ticket_num == 6 -> :called
        # Some missed tickets
        ticket_num <= 8 -> :missed
        # Rest are waiting
        true -> :waiting
      end

    # Calculate timestamps based on status
    # 5 min intervals
    base_time = DateTime.add(DateTime.utc_now(), -ticket_num * 300, :second)

    {called_at, served_at, completed_at} =
      case status do
        :completed ->
          called = DateTime.add(base_time, 60, :second)
          served = DateTime.add(called, 120, :second)
          completed = DateTime.add(served, Enum.random(300..1800), :second)
          {called, served, completed}

        :serving ->
          called = DateTime.add(base_time, 60, :second)
          served = DateTime.add(called, 120, :second)
          {called, served, nil}

        :called ->
          called = DateTime.add(base_time, 60, :second)
          {called, nil, nil}

        :missed ->
          called = DateTime.add(base_time, 60, :second)
          {called, nil, nil}

        :waiting ->
          {nil, nil, nil}
      end

    ticket_attrs = %{
      ticket_number: ticket_num,
      status: status,
      customer_name: customer_name,
      customer_phone: phone,
      service_type: service_type,
      notes: "Sample ticket for #{service_type}",
      # Most normal priority
      priority: Enum.random([:normal, :normal, :normal, :high, :low]),
      called_at: called_at,
      served_at: served_at,
      completed_at: completed_at,
      queue_id: queue.id,
      inserted_at: base_time,
      updated_at: completed_at || served_at || called_at || base_time
    }

    %Ticket{}
    |> Ticket.changeset(ticket_attrs)
    |> Repo.insert!()
  end)

  # Update queue counters to match created tickets
  current_ticket_number = ticket_count

  last_served =
    case Enum.filter(1..ticket_count, fn n -> n <= 5 end) do
      [] -> 0
      served_tickets -> Enum.max(served_tickets)
    end

  queue
  |> Queue.counter_changeset(%{
    current_ticket_number: current_ticket_number,
    last_served_ticket_number: last_served
  })
  |> Repo.update!()

  Logger.info("📊 Updated queue counters - Current: #{current_ticket_number}, Last Served: #{last_served}")
end)

# Summary statistics
total_queues = length(created_queues)
total_tickets = Repo.aggregate(Ticket, :count, :id)

Logger.info("""

🎉 Virtual Queues seeding completed!

📊 Summary:
   • #{total_queues} queues created
   • #{total_tickets} tickets created
   • Organization: #{org.name}

🎫 Queue Status:
#{Enum.map_join(created_queues, "\n", fn q ->
  ticket_count = Repo.aggregate(Ticket, :count, :id, where: [queue_id: q.id])
  "   • #{q.name}: #{String.upcase(to_string(q.status))} (#{ticket_count} tickets)"
end)}

🚀 You can now test the Virtual Queues system!
""")

Logger.info("✅ Virtual Queues seeding completed successfully!")
