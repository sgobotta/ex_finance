defmodule ExFinanceWeb.Admin.Instruments.CedearLive.Show do
  use ExFinanceWeb, :live_view

  alias ExFinance.Instruments

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _uri, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:cedear, Instruments.get_cedear!(id))}
  end

  defp page_title(:show), do: "Show Cedear"
  defp page_title(:edit), do: "Edit Cedear"
end
