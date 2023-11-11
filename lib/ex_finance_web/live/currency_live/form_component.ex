defmodule ExFinanceWeb.CurrencyLive.FormComponent do
  use ExFinanceWeb, :live_component

  alias ExFinance.Currencies

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>
          Use this form to manage currency records in your database.
        </:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="currency-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label="Name" />
        <.input field={@form[:type]} type="text" label="Type" />
        <.input
          field={@form[:variation_percent]}
          type="number"
          label="Variation percent"
          step="any"
        />
        <.input
          field={@form[:variation_price]}
          type="number"
          label="Variation price"
          step="any"
        />
        <.input
          field={@form[:info_type]}
          type="select"
          label="Info type"
          prompt="Choose a value"
          options={Ecto.Enum.values(ExFinance.Currencies.Currency, :info_type)}
        />
        <.input
          field={@form[:buy_price]}
          type="number"
          label="Buy price"
          step="any"
        />
        <.input
          field={@form[:sell_price]}
          type="number"
          label="Sell price"
          step="any"
        />
        <.input
          field={@form[:price_updated_at]}
          type="datetime-local"
          label="Price updated at"
        />
        <:actions>
          <.button phx-disable-with="Saving...">Save Currency</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{currency: currency} = assigns, socket) do
    changeset = Currencies.change_currency(currency)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"currency" => currency_params}, socket) do
    changeset =
      socket.assigns.currency
      |> Currencies.change_currency(currency_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"currency" => currency_params}, socket) do
    save_currency(socket, socket.assigns.action, currency_params)
  end

  defp save_currency(socket, :edit, currency_params) do
    case Currencies.update_currency(socket.assigns.currency, currency_params) do
      {:ok, currency} ->
        notify_parent({:saved, currency})

        {:noreply,
         socket
         |> put_flash(:info, "Currency updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_currency(socket, :new, currency_params) do
    case Currencies.create_currency(currency_params) do
      {:ok, currency} ->
        notify_parent({:saved, currency})

        {:noreply,
         socket
         |> put_flash(:info, "Currency created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
