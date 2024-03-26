defmodule ExFinanceWeb.Navigation.Components do
  @moduledoc """
  Convenience components module to implement navigation actions.
  """
  use Phoenix.Component

  @doc """
  Renders a button to navigate backwards
  """
  attr :navigate, :string, required: true

  def navigation_back(assigns) do
    ~H"""
    <a href="" class="hover:text-zinc-700 hover:dark:text-zinc-300">
      <.action navigate={@navigate}>
        <ExFinanceWeb.CoreComponents.icon
          name="hero-arrow-left-solid"
          class="h-5 w-5"
        />
      </.action>
    </a>
    """
  end

  @doc """
  Renders a back navigation link without inner blocks.

  ## Examples

      <.action navigate={~p"/posts"}>
        <.icon name="hero-arrow-left-solid" class="h-5 w-5" />
      <./action>
  """
  attr :navigate, :any, required: true
  slot :inner_block, required: true

  def action(assigns) do
    ~H"""
    <.link
      navigate={@navigate}
      class={[
        "cursor-default",
        "flex items-center p-4 m-2 w-12 h-12",
        "transition-shadow transition-all duration-500",
        "shadow-outer-sm dark:shadow-outer-sm",
        "hover:shadow-outer-xs hover:dark:shadow-outer-xs",
        "active:shadow-inner-xs active:dark:shadow-inner-xs",
        "active:bg-gray-300/50 active:dark:bg-gray-600/50",
        "rounded-full"
      ]}
    >
      <div class={[
        "text-sm font-semibold leading-6",
        "text-zinc-900 hover:text-zinc-700 dark:text-zinc-100 hover:dark:text-zinc-300",
        "transition-colors duration-500"
      ]}>
        <%= render_slot(@inner_block) %>
      </div>
    </.link>
    """
  end
end
