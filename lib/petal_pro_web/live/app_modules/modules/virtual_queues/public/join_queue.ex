defmodule PetalProWeb.VirtualQueues.DisplayQueueLive.JoinQueue do
  @moduledoc false
  use PetalProWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <h1>Join Queue</h1>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end
end
