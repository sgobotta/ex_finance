defmodule ExFinanceWeb.Admin.CurrencyLiveTest do
  @moduledoc false

  use ExFinanceWeb.ConnCase

  import Phoenix.LiveViewTest
  import ExFinance.CurrenciesFixtures

  @create_attrs %{
    buy_price: "120.5",
    info_type: :reference,
    name: "some name",
    price_updated_at: "2023-11-10T04:45:00",
    sell_price: "120.5",
    type: "some-type",
    variation_percent: "120.5"
  }
  @update_attrs %{
    buy_price: "456.7",
    info_type: :market,
    name: "some updated name",
    price_updated_at: "2023-11-11T04:45:00",
    sell_price: "456.7",
    variation_percent: "456.7"
  }
  @invalid_attrs %{
    buy_price: nil,
    info_type: nil,
    name: nil,
    price_updated_at: nil,
    sell_price: nil,
    variation_percent: nil
  }

  defp create_currency(_context) do
    currency = currency_fixture()
    %{currency: currency}
  end

  describe "Index" do
    setup [:create_currency, :register_and_log_in_admin]

    test "lists all currencies", %{conn: conn, currency: currency} do
      {:ok, _index_live, html} = live(conn, ~p"/admin/currencies")

      assert html =~ "Listing Currencies"
      assert html =~ currency.name
    end

    test "saves new currency", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/admin/currencies")

      assert index_live |> element("a", "New Currency") |> render_click() =~
               "New Currency"

      assert_patch(index_live, ~p"/admin/currencies/new")

      assert index_live
             |> form("#currency-form", currency: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#currency-form", currency: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/admin/currencies")

      html = render(index_live)
      assert html =~ "Currency created successfully"
      assert html =~ "some name"
    end

    test "updates currency in listing", %{conn: conn, currency: currency} do
      {:ok, index_live, _html} = live(conn, ~p"/admin/currencies")

      assert index_live
             |> element("#currencies-#{currency.id} a", "Edit")
             |> render_click() =~
               "Edit Currency"

      assert_patch(index_live, ~p"/admin/currencies/#{currency}/edit")

      assert index_live
             |> form("#currency-form", currency: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#currency-form", currency: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/admin/currencies")

      html = render(index_live)
      assert html =~ "Currency updated successfully"
      assert html =~ "some updated name"
    end

    test "deletes currency in listing", %{conn: conn, currency: currency} do
      {:ok, index_live, _html} = live(conn, ~p"/admin/currencies")

      assert index_live
             |> element("#currencies-#{currency.id} a", "Delete")
             |> render_click()

      refute has_element?(index_live, "#currencies-#{currency.id}")
    end
  end

  describe "Show" do
    setup [:create_currency, :register_and_log_in_admin]

    test "displays currency", %{conn: conn, currency: currency} do
      {:ok, _show_live, html} = live(conn, ~p"/admin/currencies/#{currency}")

      assert html =~ "Show Currency"
      assert html =~ currency.name
    end

    test "updates currency within modal", %{conn: conn, currency: currency} do
      {:ok, show_live, _html} = live(conn, ~p"/admin/currencies/#{currency}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Currency"

      assert_patch(show_live, ~p"/admin/currencies/#{currency}/show/edit")

      assert show_live
             |> form("#currency-form", currency: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#currency-form", currency: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/admin/currencies/#{currency}")

      html = render(show_live)
      assert html =~ "Currency updated successfully"
      assert html =~ "some updated name"
    end
  end
end
