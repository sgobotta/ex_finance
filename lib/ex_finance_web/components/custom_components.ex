defmodule ExFinanceWeb.CustomComponents do
  @moduledoc false
  use Phoenix.Component

  alias ExFinanceWeb.CoreComponents
  alias Phoenix.LiveView.JS

  import ExFinanceWeb.Gettext

  @doc """
  Renders a button to toggle the application theme
  """
  attr :theme, :string, required: true

  def toggle_theme_button(assigns) do
    ~H"""
    <div
      class="flex items-center gap-4 font-semibold leading-6 text-zinc-900"
      phx-hook="Theme"
      id="theme-hook"
    >
      <a
        class="hover:text-zinc-700 cursor-pointer h-5 w-5 leading-3"
        href="#"
        phx-key=";"
        phx-window-keydown={JS.dispatch("toggle-theme")}
        phx-click={JS.dispatch("toggle-theme")}
        tabindex="0"
      >
        <%= if @theme === "dark" do %>
          <CoreComponents.icon
            id="toggle-theme-icon"
            name="hero-sun-solid"
            class="text-black dark:text-white h-5 w-5"
          />
        <% else %>
          <CoreComponents.icon
            id="toggle-theme-icon"
            name="hero-moon-solid"
            class="text-black dark:text-white h-5 w-5"
          />
        <% end %>
      </a>
    </div>
    """
  end

  def cafecito_button(assigns) do
    ~H"""
    <a
      href={"https://cafecito.app/#{@cafecito_username}"}
      rel="noopener"
      target="_blank"
      class="transition duration-300 hover:scale-[1.1] hover:shadow-lg w-28"
    >
      <img
        srcset="https://cdn.cafecito.app/imgs/buttons/button_2.png 1x, https://cdn.cafecito.app/imgs/buttons/button_2_2x.png 2x, https://cdn.cafecito.app/imgs/buttons/button_2_3.75x.png 3.75x"
        src="https://cdn.cafecito.app/imgs/buttons/button_2.png"
        alt={gettext("Invite me a coffee in cafecito.app")}
      />
    </a>
    """
  end

  attr :id, :string, default: "presence-disclaimer"
  attr :disclaimer_content, :string, required: true

  def presence_disclaimer(assigns) do
    ~H"""
    <.live_component
      id={@id}
      module={ExFinanceWeb.CustomComponents.PresenceDisclaimer}
      disclaimer_content={@disclaimer_content}
    />
    """
  end
end
