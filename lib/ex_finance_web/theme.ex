defmodule ExFinanceWeb.Theme do
  @moduledoc false

  def on_mount(:fetch_theme, _params, _session, socket) do
    {:cont, mount_current_theme(socket)}
  end

  defp mount_current_theme(socket) do
    Phoenix.Component.assign(
      socket,
      :theme,
      Phoenix.LiveView.get_connect_params(socket)["_theme"]
    )
  end

  def theme_helpers do
    quote do
      def handle_event("toggle-theme", %{"theme" => theme}, socket) do
        {:noreply, assign(socket, :theme, theme)}
      end
    end
  end
end
