defmodule PetalProWeb.SubscribedLive do
  @moduledoc false
  use PetalProWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.layout current_page={:subscribed} current_user={@current_user}>
      <.container class="my-12">
        <.h2 class="text-center">Hello, Subscribed user!</.h2>
      </.container>
    </.layout>
    """
  end
end
