defmodule ExFinanceWeb.Navigation do
  @moduledoc """
  Convenience module to define navigation actions for liveviews.
  """

  def action(_opts \\ []) do
    quote do
      @callback render_header_action(any()) :: any()

      @spec assign_header_action(Phoenix.LiveView.Socket.t()) ::
              Phoenix.LiveView.Socket.t()
      defp assign_header_action(socket) do
        Phoenix.Component.assign(
          socket,
          :header_action,
          render_header_action(socket)
        )
      end
    end
  end

  @doc """
  When used, dispatch to the appropriate feature.
  """
  defmacro __using__({which, opts}) when is_atom(which) do
    apply(__MODULE__, which, [opts])
  end

  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
