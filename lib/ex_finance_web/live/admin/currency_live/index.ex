defmodule ExFinanceWeb.Admin.CurrencyLive.Index do
  use ExFinanceWeb, :live_view
  use ExFinanceWeb.Navigation, :action

  alias ExFinance.Currencies
  alias ExFinance.Currencies.Currency

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :currencies, Currencies.list_currencies())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply,
     socket
     |> assign_header_action()
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Currency")
    |> assign(:currency, Currencies.get_currency!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Currency")
    |> assign(:currency, %Currency{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Currencies")
    |> assign(:currency, nil)
  end

  @impl true
  def handle_info(
        {ExFinanceWeb.Admin.CurrencyLive.FormComponent, {:saved, currency}},
        socket
      ) do
    {:noreply, stream_insert(socket, :currencies, currency)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    currency = Currencies.get_currency!(id)
    {:ok, _} = Currencies.delete_currency(currency)

    {:noreply, stream_delete(socket, :currencies, currency)}
  end

  defp render_header_action(assigns) do
    ~H"""
    <.navigation_back navigate={~p"/"} />
    """
  end
end
