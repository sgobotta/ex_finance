defmodule ExFinanceWeb.Public.HomeLive.Index do
  @moduledoc false
  use ExFinanceWeb, {:live_view, layout: false}
  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end
end
