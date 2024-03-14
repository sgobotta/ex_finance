defmodule ExFinanceWeb.CustomComponents do
  @moduledoc false
  use Phoenix.Component

  import ExFinanceWeb.Gettext

  def cafecito_button(assigns) do
    ~H"""
    <a
      href="https://cafecito.app/sgobotta"
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
end
