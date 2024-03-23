defmodule ExFinanceWeb.Admin.CurrencyLive.Show do
  use ExFinanceWeb, :live_view
  use ExFinanceWeb.Navigation, :action

  alias ExFinance.Currencies

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _uri, socket) do
    {:noreply,
     socket
     |> assign_header_action()
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:currency, Currencies.get_currency!(id))}
  end

  defp page_title(:show), do: "Show Currency"
  defp page_title(:edit), do: "Edit Currency"

  defp render_header_action(assigns) do
    ~H"""
    <.navigation_back navigate={~p"/admin/currencies"} />
    """
  end
end
