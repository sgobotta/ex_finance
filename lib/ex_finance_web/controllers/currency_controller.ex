defmodule ExFinanceWeb.CurrencyController do
  use ExFinanceWeb, :controller

  alias ExFinance.Currencies
  alias ExFinance.Currencies.Currency

  action_fallback ExFinanceWeb.FallbackController

  def index(conn, _params) do
    currencies = Currencies.list_currencies()
    render(conn, :index, currencies: currencies)
  end

  def create(conn, %{"currency" => currency_params}) do
    with {:ok, %Currency{} = currency} <-
           Currencies.create_currency(currency_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", ~p"/api/currencies/#{currency}")
      |> render(:show, currency: currency)
    end
  end

  def show(conn, %{"id" => id}) do
    currency = Currencies.get_currency!(id)
    render(conn, :show, currency: currency)
  end

  def update(conn, %{"id" => id, "currency" => currency_params}) do
    currency = Currencies.get_currency!(id)

    with {:ok, %Currency{} = currency} <-
           Currencies.update_currency(currency, currency_params) do
      render(conn, :show, currency: currency)
    end
  end

  def delete(conn, %{"id" => id}) do
    currency = Currencies.get_currency!(id)

    with {:ok, %Currency{}} <- Currencies.delete_currency(currency) do
      send_resp(conn, :no_content, "")
    end
  end
end
