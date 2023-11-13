defmodule ExFinanceWeb.Public.CurrencyLive.Show do
  use ExFinanceWeb, :live_view

  alias ExFinance.Currencies

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _uri, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:currency, Currencies.get_currency!(id))}
  end

  defp page_title(:show), do: "Show Currency"
end
