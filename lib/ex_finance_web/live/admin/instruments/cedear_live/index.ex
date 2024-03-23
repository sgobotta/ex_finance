defmodule ExFinanceWeb.Admin.Instruments.CedearLive.Index do
  use ExFinanceWeb, :live_view
  use ExFinanceWeb.Navigation, :action

  alias ExFinance.Instruments
  alias ExFinance.Instruments.Cedear

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :cedears, Instruments.list_cedears())}
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
    |> assign(:page_title, "Edit Cedear")
    |> assign(:cedear, Instruments.get_cedear!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Cedear")
    |> assign(:cedear, %Cedear{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Cedears")
    |> assign(:cedear, nil)
  end

  @impl true
  def handle_info(
        {ExFinanceWeb.Admin.Instruments.CedearLive.FormComponent,
         {:saved, cedear}},
        socket
      ) do
    {:noreply, stream_insert(socket, :cedears, cedear)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    cedear = Instruments.get_cedear!(id)
    {:ok, _} = Instruments.delete_cedear(cedear)

    {:noreply, stream_delete(socket, :cedears, cedear)}
  end

  defp render_header_action(assigns) do
    ~H"""
    <.navigation_back navigate={~p"/"} />
    """
  end
end
