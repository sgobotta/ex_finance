defmodule ExFinanceWeb.Public.CurrencyLive.Index do
  use ExFinanceWeb, :live_view

  alias ExFinance.Currencies

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :currencies, Currencies.list_currencies())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Currencies")
    |> assign(:currency, nil)
  end
end
