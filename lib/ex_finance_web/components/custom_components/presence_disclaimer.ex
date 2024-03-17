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
    users =
      Map.delete(assigns.presences, assigns.current_presence)
      |> Map.keys()
      |> length

    assigns = assign(assigns, :users, users)

    render_disclaimer(assigns)
  end

  defp render_disclaimer(%{users: 0} = assigns) do
    ~H"""
    <div />
    """
  end

  defp render_disclaimer(%{users: _users} = assigns) do
    ~H"""
    <div>
      <%= if connected?(@socket) do %>
        <div class="py-2 text-xs italic cursor-default">
          <p>
            <%= ngettext(
              "You and other user are browsing this page",
              "You and %{users} more users are browsing this page",
              @users,
              users: @users
            ) %>
          </p>
        </div>
      <% else %>
        <div />
      <% end %>
    </div>
    """
  end
end
