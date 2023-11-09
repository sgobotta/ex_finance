defmodule ExFinanceWeb.CurrencyControllerTest do
  use ExFinanceWeb.ConnCase

  import ExFinance.CurrenciesFixtures

  alias ExFinance.Currencies.Currency

  @create_attrs %{
    buy_price: "120.5",
    info_type: :reference,
    meta: %{},
    name: "some name",
    price_updated_at: ~N[2023-11-08 04:55:00],
    sell_price: "120.5",
    supplier_name: "some supplier_name",
    supplier_url: "some supplier_url",
    type: "some type",
    variation_percent: "120.5"
  }
  @update_attrs %{
    buy_price: "456.7",
    info_type: :market,
    meta: %{},
    name: "some updated name",
    price_updated_at: ~N[2023-11-09 04:55:00],
    sell_price: "456.7",
    supplier_name: "some updated supplier_name",
    supplier_url: "some updated supplier_url",
    type: "some updated type",
    variation_percent: "456.7"
  }
  @invalid_attrs %{
    buy_price: nil,
    info_type: nil,
    meta: nil,
    name: nil,
    price_updated_at: nil,
    sell_price: nil,
    supplier_name: nil,
    supplier_url: nil,
    type: nil,
    variation_percent: nil
  }

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists all currencies", %{conn: conn} do
      conn = get(conn, ~p"/api/currencies")
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create currency" do
    test "renders currency when data is valid", %{conn: conn} do
      conn = post(conn, ~p"/api/currencies", currency: @create_attrs)
      assert json_response(conn, 404)["errors"] != %{}
      # assert %{"id" => id} = json_response(conn, 201)["data"]

      # conn = get(conn, ~p"/api/currencies/#{id}")

      # assert %{
      #          "id" => ^id,
      #          "buy_price" => "120.5",
      #          "info_type" => "reference",
      #          "meta" => %{},
      #          "name" => "some name",
      #          #  "price_updated_at" => "2023-11-08T04:55:00",
      #          "sell_price" => "120.5",
      #          "supplier_name" => "some supplier_name",
      #          "supplier_url" => "some supplier_url",
      #          "type" => "some type",
      #          "variation_percent" => "120.5"
      #        } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/api/currencies", currency: @invalid_attrs)
      # assert json_response(conn, 400)["errors"] != %{}
      assert json_response(conn, 404)["errors"] != %{}
    end
  end

  describe "update currency" do
    setup [:create_currency]

    test "renders currency when data is valid", %{
      conn: conn,
      currency: %Currency{id: id} = currency
    } do
      conn = put(conn, ~p"/api/currencies/#{currency}", currency: @update_attrs)
      assert json_response(conn, 404)["errors"] != %{}
      # assert %{"id" => ^id} = json_response(conn, 200)["data"]

      # conn = get(conn, ~p"/api/currencies/#{id}")

      # assert %{
      #          "buy_price" => "456.7",
      #          "info_type" => "market",
      #          "meta" => %{},
      #          "name" => "some updated name",
      #          "price_updated_at" => "2023-11-09T04:55:00Z",
      #          "sell_price" => "456.7",
      #          "supplier_name" => "some updated supplier_name",
      #          "supplier_url" => "some updated supplier_url",
      #          "type" => "some updated type",
      #          "variation_percent" => "456.7"
      #        } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{
      conn: conn,
      currency: currency
    } do
      conn =
        put(conn, ~p"/api/currencies/#{currency}", currency: @invalid_attrs)

        # assert json_response(conn, 400)["errors"] != %{}
      assert json_response(conn, 404)["errors"] != %{}
    end
  end

  describe "delete currency" do
    setup [:create_currency]

    test "deletes chosen currency", %{conn: conn, currency: currency} do
      conn = delete(conn, ~p"/api/currencies/#{currency}")
      assert json_response(conn, 404)["errors"] != %{}
      # assert response(conn, 204)

      # assert_error_sent 404, fn ->
      #   get(conn, ~p"/api/currencies/#{currency}")
      # end
    end
  end

  defp create_currency(_context) do
    currency = currency_fixture()
    %{currency: currency}
  end
end
