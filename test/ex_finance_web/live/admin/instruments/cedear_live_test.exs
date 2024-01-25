defmodule ExFinanceWeb.Admin.Instruments.CedearLiveTest do
  use ExFinanceWeb.ConnCase

  import Phoenix.LiveViewTest
  import ExFinance.InstrumentsFixtures

  @create_attrs %{
    country: "some country",
    dividend_payment_frequency: "some dividend_payment_frequency",
    industry: "some industry",
    name: "some name",
    origin_ticker: "some origin_ticker",
    ratio: "120.5",
    supplier_name: "some supplier_name",
    symbol: "some symbol",
    underlying_market: "some underlying_market",
    underlying_security_value: "some underlying_security_value",
    web_link: "some web_link"
  }
  @update_attrs %{
    country: "some updated country",
    dividend_payment_frequency: "some updated dividend_payment_frequency",
    industry: "some updated industry",
    name: "some updated name",
    origin_ticker: "some updated origin_ticker",
    ratio: "456.7",
    supplier_name: "some updated supplier_name",
    symbol: "some updated symbol",
    underlying_market: "some updated underlying_market",
    underlying_security_value: "some updated underlying_security_value",
    web_link: "some updated web_link"
  }
  @invalid_attrs %{
    country: nil,
    dividend_payment_frequency: nil,
    industry: nil,
    name: nil,
    origin_ticker: nil,
    ratio: nil,
    supplier_name: nil,
    symbol: nil,
    underlying_market: nil,
    underlying_security_value: nil,
    web_link: nil
  }

  defp create_cedear(_context) do
    cedear = cedear_fixture()
    %{cedear: cedear}
  end

  describe "Index" do
    setup [:create_cedear, :register_and_log_in_admin]

    test "lists all cedears", %{conn: conn, cedear: cedear} do
      {:ok, _index_live, html} = live(conn, ~p"/admin/instruments/cedears")

      assert html =~ "Listing Cedears"
      assert html =~ cedear.country
    end

    test "saves new cedear", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/admin/instruments/cedears")

      assert index_live |> element("a", "New Cedear") |> render_click() =~
               "New Cedear"

      assert_patch(index_live, ~p"/admin/instruments/cedears/new")

      assert index_live
             |> form("#cedear-form", cedear: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#cedear-form", cedear: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/admin/instruments/cedears")

      html = render(index_live)
      assert html =~ "Cedear created successfully"
      assert html =~ "some country"
    end

    test "updates cedear in listing", %{conn: conn, cedear: cedear} do
      {:ok, index_live, _html} = live(conn, ~p"/admin/instruments/cedears")

      assert index_live
             |> element("#cedears-#{cedear.id} a", "Edit")
             |> render_click() =~
               "Edit Cedear"

      assert_patch(index_live, ~p"/admin/instruments/cedears/#{cedear}/edit")

      assert index_live
             |> form("#cedear-form", cedear: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#cedear-form", cedear: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/admin/instruments/cedears")

      html = render(index_live)
      assert html =~ "Cedear updated successfully"
      assert html =~ "some updated country"
    end

    test "deletes cedear in listing", %{conn: conn, cedear: cedear} do
      {:ok, index_live, _html} = live(conn, ~p"/admin/instruments/cedears")

      assert index_live
             |> element("#cedears-#{cedear.id} a", "Delete")
             |> render_click()

      refute has_element?(index_live, "#cedears-#{cedear.id}")
    end
  end

  describe "Show" do
    setup [:create_cedear, :register_and_log_in_admin]

    test "displays cedear", %{conn: conn, cedear: cedear} do
      {:ok, _show_live, html} =
        live(conn, ~p"/admin/instruments/cedears/#{cedear}")

      assert html =~ "Show Cedear"
      assert html =~ cedear.country
    end

    test "updates cedear within modal", %{conn: conn, cedear: cedear} do
      {:ok, show_live, _html} =
        live(conn, ~p"/admin/instruments/cedears/#{cedear}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Cedear"

      assert_patch(
        show_live,
        ~p"/admin/instruments/cedears/#{cedear}/show/edit"
      )

      assert show_live
             |> form("#cedear-form", cedear: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#cedear-form", cedear: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/admin/instruments/cedears/#{cedear}")

      html = render(show_live)
      assert html =~ "Cedear updated successfully"
      assert html =~ "some updated country"
    end
  end
end
