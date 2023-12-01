defmodule ExFinanceWeb.Admin.Instruments.CedearLive.FormComponent do
  use ExFinanceWeb, :live_component

  alias ExFinance.Instruments

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>
          Use this form to manage cedear records in your database.
        </:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="cedear-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label="Name" />
        <.input field={@form[:ratio]} type="number" label="Ratio" step="any" />
        <.input field={@form[:symbol]} type="text" label="Symbol" />
        <.input field={@form[:origin_ticker]} type="text" label="Origin ticker" />
        <.input
          field={@form[:underlying_security_value]}
          type="text"
          label="Underlying security value"
        />
        <.input field={@form[:country]} type="text" label="Country" />
        <.input
          field={@form[:underlying_market]}
          type="text"
          label="Underlying market"
        />
        <.input
          field={@form[:dividend_payment_frequency]}
          type="text"
          label="Dividend payment frequency"
        />
        <.input field={@form[:industry]} type="text" label="Industry" />
        <.input field={@form[:web_link]} type="text" label="Web link" />
        <.input field={@form[:supplier_name]} type="text" label="Supplier name" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Cedear</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{cedear: cedear} = assigns, socket) do
    changeset = Instruments.change_cedear(cedear)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"cedear" => cedear_params}, socket) do
    changeset =
      socket.assigns.cedear
      |> Instruments.change_cedear(cedear_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"cedear" => cedear_params}, socket) do
    save_cedear(socket, socket.assigns.action, cedear_params)
  end

  defp save_cedear(socket, :edit, cedear_params) do
    case Instruments.update_cedear(socket.assigns.cedear, cedear_params) do
      {:ok, cedear} ->
        notify_parent({:saved, cedear})

        {:noreply,
         socket
         |> put_flash(:info, "Cedear updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_cedear(socket, :new, cedear_params) do
    case Instruments.create_cedear(cedear_params) do
      {:ok, cedear} ->
        notify_parent({:saved, cedear})

        {:noreply,
         socket
         |> put_flash(:info, "Cedear created successfully")
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
