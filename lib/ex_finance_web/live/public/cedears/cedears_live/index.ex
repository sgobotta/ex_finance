defmodule ExFinanceWeb.Public.CedearsLive.Index do
  use ExFinanceWeb, :live_view

  alias ExFinance.Instruments
  alias Phoenix.LiveView.JS

  @impl true
  def mount(_params, _session, socket) do
    socket = assign(socket, cedears: [])
    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  @impl true
  def handle_event("change", %{"search" => %{"query" => ""}}, socket) do
    socket = assign(socket, :cedears, [])
    {:noreply, socket}
  end

  def handle_event("change", %{"search" => %{"query" => search_query}}, socket) do
    cedears = Instruments.search_cedear(search_query)
    socket = assign(socket, :cedears, cedears)

    {:noreply, socket}
  end

  def open_modal(js \\ %JS{}) do
    js
    |> JS.show(
      to: "#searchbox_container",
      transition:
        {"transition ease-out duration-200", "opacity-0 scale-95",
         "opacity-100 scale-100"}
    )
    |> JS.show(
      to: "#searchbar-dialog",
      transition:
        {"transition ease-in duration-100", "opacity-0", "opacity-100"}
    )
    |> JS.focus(to: "#search-input")
  end

  def hide_modal(js \\ %JS{}) do
    js
    |> JS.hide(
      to: "#searchbar-searchbox_container",
      transition:
        {"transition ease-in duration-100", "opacity-100 scale-100",
         "opacity-0 scale-95"}
    )
    |> JS.hide(
      to: "#searchbar-dialog",
      transition:
        {"transition ease-in duration-100", "opacity-100", "opacity-0"}
    )
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Cedears")
    |> assign(:section_title, "Buscador de cedears")
  end
end
