defmodule PetalPro.QueueEventsTimer do
  @moduledoc """
  Global events timer that broadcasts to all orgs based on their permissions.
  Single source of truth for merchandise and footer news display state.
  """
  use GenServer

  alias PetalPro.Orgs.Permissions

  require Logger

  # TODO: move footer_news to queue config
  @footer_news %{interval: 2_000, display_interval: 2_000}
  @merchandise %{interval: 60_000 * 30, display_interval: 30_000}

  defstruct [:show_merchandise, :show_footer_news, :subscribers, :org_count]

  ## Client API

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def subscribe(org_id) do
    GenServer.call(__MODULE__, {:subscribe, org_id})
  end

  def unsubscribe(org_id) do
    GenServer.call(__MODULE__, {:unsubscribe, org_id})
  end

  def get_state do
    GenServer.call(__MODULE__, :get_state)
  end

  def get_stats do
    GenServer.call(__MODULE__, :get_stats)
  end

  ## Server Callbacks

  @impl true
  def init(_opts) do
    state = %__MODULE__{
      show_merchandise: false,
      show_footer_news: false,
      subscribers: %{},
      org_count: 0
    }

    # ✅ Initialize the timers
    schedule_show_merchandise()
    # TODO: move footer_news to queue config
    schedule_show_footer_news()

    Logger.info("Global queue events timer started")

    {:ok, state}
  end

  @impl true
  def handle_call({:subscribe, org_id}, {from_pid, _}, state) do
    Process.monitor(from_pid)

    org_pids = Map.get(state.subscribers, org_id, [])
    new_org_pids = [from_pid | org_pids]
    new_subscribers = Map.put(state.subscribers, org_id, new_org_pids)

    new_state = %{
      state
      | subscribers: new_subscribers,
        org_count: map_size(new_subscribers)
    }

    # ✅ Send current state only if org has permission
    if Permissions.can_receive_merchandise?(org_id) do
      send(from_pid, {:merchandise_state, state.show_merchandise, org_id})
    end

    if Permissions.can_receive_footer_news?(org_id) do
      send(from_pid, {:footer_news_state, state.show_footer_news, org_id})
    end

    Logger.debug("Org #{org_id} subscribed. Total orgs: #{new_state.org_count}")
    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call({:unsubscribe, org_id}, {from_pid, _}, state) do
    case Map.get(state.subscribers, org_id) do
      nil ->
        {:reply, :ok, state}

      org_pids ->
        new_org_pids = List.delete(org_pids, from_pid)

        new_subscribers =
          if Enum.empty?(new_org_pids) do
            Map.delete(state.subscribers, org_id)
          else
            Map.put(state.subscribers, org_id, new_org_pids)
          end

        new_state = %{
          state
          | subscribers: new_subscribers,
            org_count: map_size(new_subscribers)
        }

        Logger.debug("Org #{org_id} unsubscribed. Total orgs: #{new_state.org_count}")
        {:reply, :ok, new_state}
    end
  end

  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply,
     %{
       show_merchandise: state.show_merchandise,
       show_footer_news: state.show_footer_news
     }, state}
  end

  @impl true
  def handle_call(:get_stats, _from, state) do
    total_connections =
      state.subscribers
      |> Map.values()
      |> Enum.map(&length/1)
      |> Enum.sum()

    stats = %{
      show_merchandise: state.show_merchandise,
      show_footer_news: state.show_footer_news,
      org_count: state.org_count,
      total_connections: total_connections,
      orgs: Map.keys(state.subscribers)
    }

    {:reply, stats, state}
  end

  @impl true
  def handle_info(:show_merchandise, state) do
    new_state = %{state | show_merchandise: true}

    broadcast_to_all_orgs_with_free_tier(new_state)
    schedule_hide_merchandise()

    {:noreply, new_state}
  end

  @impl true
  def handle_info(:hide_merchandise, state) do
    new_state = %{state | show_merchandise: false}

    broadcast_to_all_orgs_with_free_tier(new_state)
    schedule_show_merchandise()

    {:noreply, new_state}
  end

  @impl true
  def handle_info(:show_footer_news, state) do
    new_state = %{state | show_footer_news: true}

    broadcast_to_all_subscribed_orgs(new_state)
    schedule_hide_footer_news()

    {:noreply, new_state}
  end

  @impl true
  def handle_info(:hide_footer_news, state) do
    new_state = %{state | show_footer_news: false}

    broadcast_to_all_subscribed_orgs(new_state)
    schedule_show_footer_news()

    {:noreply, new_state}
  end

  @impl true
  def handle_info({:DOWN, _ref, :process, pid, _reason}, state) do
    # Clean up when subscriber process dies
    new_subscribers =
      state.subscribers
      |> Enum.map(fn {org_id, pids} ->
        {org_id, List.delete(pids, pid)}
      end)
      |> Enum.reject(fn {_org_id, pids} -> Enum.empty?(pids) end)
      |> Map.new()

    new_state = %{
      state
      | subscribers: new_subscribers,
        org_count: map_size(new_subscribers)
    }

    {:noreply, new_state}
  end

  ## Private Functions

  defp broadcast_to_all_orgs_with_free_tier(state) do
    {broadcasted, total} = selective_broadcast(state, :merchandise_state, &Permissions.can_receive_merchandise?/1)
    Logger.debug("Merchandise broadcast: #{broadcasted}/#{total} orgs")
  end

  defp broadcast_to_all_subscribed_orgs(state) do
    {broadcasted, total} = selective_broadcast(state, :footer_news_state, &Permissions.can_receive_footer_news?/1)
    Logger.debug("Footer news broadcast: #{broadcasted}/#{total} orgs")
  end

  # ✅ Return broadcast stats for logging
  defp selective_broadcast(state, event_type, permission_check_fn) do
    {broadcasted, total} =
      Enum.reduce(state.subscribers, {0, 0}, fn {org_id, pids}, {bc, total} ->
        if permission_check_fn.(org_id) do
          message = build_message(event_type, state, org_id)
          Enum.each(pids, fn pid -> send(pid, message) end)
          {bc + 1, total + 1}
        else
          {bc, total + 1}
        end
      end)

    {broadcasted, total}
  end

  defp build_message(:merchandise_state, state, org_id) do
    {:merchandise_state, state.show_merchandise, org_id}
  end

  defp build_message(:footer_news_state, state, org_id) do
    {:footer_news_state, state.show_footer_news, org_id}
  end

  defp schedule_show_merchandise do
    Process.send_after(self(), :show_merchandise, @merchandise.interval)
  end

  defp schedule_hide_merchandise do
    Process.send_after(self(), :hide_merchandise, @merchandise.display_interval)
  end

  defp schedule_show_footer_news do
    Process.send_after(self(), :show_footer_news, @footer_news.interval)
  end

  defp schedule_hide_footer_news do
    Process.send_after(self(), :hide_footer_news, @footer_news.display_interval)
  end
end
