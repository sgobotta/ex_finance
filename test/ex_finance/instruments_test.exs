defmodule ExFinance.InstrumentsTest do
  @moduledoc false
  use ExFinance.DataCase

  alias ExFinance.Instruments

  describe "cedears" do
    alias ExFinance.Instruments.Cedear

    import ExFinance.InstrumentsFixtures

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

    test "list_cedears/0 returns all cedears" do
      cedear = cedear_fixture()
      assert Instruments.list_cedears() == [cedear]
    end

    test "get_cedear!/1 returns the cedear with given id" do
      cedear = cedear_fixture()
      assert Instruments.get_cedear!(cedear.id) == cedear
    end

    test "create_cedear/1 with valid data creates a cedear" do
      valid_attrs = %{
        country: "some country",
        dividend_payment_frequency: "some dividend_payment_frequency",
        industry: "some industry",
        name: "some name",
        origin_ticker: "some origin_ticker",
        ratio: "120.5",
        supplier_name: "some supplier name",
        symbol: "some symbol",
        underlying_market: "some underlying_market",
        underlying_security_value: "some underlying_security_value",
        web_link: "some web_link"
      }

      assert {:ok, %Cedear{} = cedear} = Instruments.create_cedear(valid_attrs)
      assert cedear.country == "some country"

      assert cedear.dividend_payment_frequency ==
               "some dividend_payment_frequency"

      assert cedear.industry == "some industry"
      assert cedear.name == "some name"
      assert cedear.origin_ticker == "some origin_ticker"
      assert cedear.ratio == Decimal.new("120.5")
      assert cedear.supplier_name == "some supplier name"
      assert cedear.symbol == "some symbol"
      assert cedear.underlying_market == "some underlying_market"

      assert cedear.underlying_security_value ==
               "some underlying_security_value"

      assert cedear.web_link == "some web_link"
    end

    test "create_cedear/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} =
               Instruments.create_cedear(@invalid_attrs)
    end

    test "update_cedear/2 with valid data updates the cedear" do
      cedear = cedear_fixture()

      update_attrs = %{
        country: "some updated country",
        dividend_payment_frequency: "some updated dividend_payment_frequency",
        industry: "some updated industry",
        name: "some updated name",
        origin_ticker: "some updated origin_ticker",
        ratio: "456.7",
        symbol: "some updated symbol",
        underlying_market: "some updated underlying_market",
        underlying_security_value: "some updated underlying_security_value",
        web_link: "some updated web_link"
      }

      assert {:ok, %Cedear{} = cedear} =
               Instruments.update_cedear(cedear, update_attrs)

      assert cedear.country == "some updated country"

      assert cedear.dividend_payment_frequency ==
               "some updated dividend_payment_frequency"

      assert cedear.industry == "some updated industry"
      assert cedear.name == "some updated name"
      assert cedear.origin_ticker == "some updated origin_ticker"
      assert cedear.ratio == Decimal.new("456.7")
      assert cedear.symbol == "some updated symbol"
      assert cedear.underlying_market == "some updated underlying_market"

      assert cedear.underlying_security_value ==
               "some updated underlying_security_value"

      assert cedear.web_link == "some updated web_link"
    end

    test "update_cedear/2 with invalid data returns error changeset" do
      cedear = cedear_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Instruments.update_cedear(cedear, @invalid_attrs)

      assert cedear == Instruments.get_cedear!(cedear.id)
    end

    test "delete_cedear/1 deletes the cedear" do
      cedear = cedear_fixture()
      assert {:ok, %Cedear{}} = Instruments.delete_cedear(cedear)

      assert_raise Ecto.NoResultsError, fn ->
        Instruments.get_cedear!(cedear.id)
      end
    end

    test "change_cedear/1 returns a cedear changeset" do
      cedear = cedear_fixture()
      assert %Ecto.Changeset{} = Instruments.change_cedear(cedear)
    end
  end
end
