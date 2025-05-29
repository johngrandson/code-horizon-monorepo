defmodule PetalProWeb.VirtualQueues.DisplayQueueLive.ListQueues do
  @moduledoc false
  use PetalProWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <h1>{@page_description}</h1>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    socket =
      assign(socket, :page_description, "List Queues")

    {:ok, socket}
  end
end
