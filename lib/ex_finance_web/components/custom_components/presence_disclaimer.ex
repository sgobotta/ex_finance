defmodule ExFinanceWeb.CustomComponents.PresenceDisclaimer do
  @moduledoc false
  use ExFinanceWeb, :live_component

  @impl true
  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <%= if connected?(@socket) do %>
        <div class="py-2 text-xs italic cursor-default">
          <p>
            <%= @disclaimer_content %>
          </p>
        </div>
      <% else %>
        <div />
      <% end %>
    </div>
    """
  end
end
