defmodule ExFinanceWeb.CustomComponents do
  @moduledoc false
  use Phoenix.Component

  alias Phoenix.HTML
  alias Phoenix.LiveView.JS
  import ExFinanceWeb.Gettext

  def cafecito_button(assigns) do
    ~H"""
    <a href="https://cafecito.app/sgobotta" rel="noopener" target="_blank">
      <img
        srcset="https://cdn.cafecito.app/imgs/buttons/button_6.png 1x, https://cdn.cafecito.app/imgs/buttons/button_6_2x.png 2x, https://cdn.cafecito.app/imgs/buttons/button_6_3.75x.png 3.75x"
        src="https://cdn.cafecito.app/imgs/buttons/button_6.png"
        alt={gettext("Invite me a coffee in cafecito.app")}
      />
    </a>
    """
  end
end
