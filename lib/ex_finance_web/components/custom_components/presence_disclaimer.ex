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
        <div class="
          text-xs italic text-zinc-700 cursor-default
          rounded-b-xl overflow-hidden shadow-2xl
          border-r-[0.75px] border-b-[0.5px] border-l-[0.75px] border-zinc-300 border-dotted
        ">
          <div class="backdrop-blur-md p-2">
            <p>
              <%= @disclaimer_content %>
            </p>
          </div>
        </div>
      <% else %>
        <div />
      <% end %>
    </div>
    """
  end
end
