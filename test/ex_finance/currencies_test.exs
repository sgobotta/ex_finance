defmodule ExFinance.CurrenciesTest do
  use ExFinance.DataCase

  alias ExFinance.Currencies

  describe "currencies" do
    alias ExFinance.Currencies.Currency

    import ExFinance.CurrenciesFixtures

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

    test "list_currencies/0 returns all currencies" do
      currency = currency_fixture()
      assert Currencies.list_currencies() == [currency]
    end

    test "get_currency!/1 returns the currency with given id" do
      currency = currency_fixture()
      assert Currencies.get_currency!(currency.id) == currency
    end

    test "create_currency/1 with valid data creates a currency" do
      valid_attrs = %{
        buy_price: "120.5",
        info_type: :reference,
        meta: %{},
        name: "some name",
        price_updated_at: ~U[2023-11-08 04:55:00.718007Z],
        sell_price: "120.5",
        supplier_name: "some supplier_name",
        supplier_url: "some supplier_url",
        type: "some type",
        variation_percent: "120.5"
      }

      assert {:ok, %Currency{} = currency} =
               Currencies.create_currency(valid_attrs)

      assert currency.buy_price == Decimal.new("120.5")
      assert currency.info_type == :reference
      assert currency.meta == %{}
      assert currency.name == "some name"
      # assert currency.price_updated_at == ~U[2023-11-08 04:55:00.718007Z]
      assert currency.sell_price == Decimal.new("120.5")
      assert currency.supplier_name == "some supplier_name"
      assert currency.supplier_url == "some supplier_url"
      assert currency.type == "some type"
      assert currency.variation_percent == Decimal.new("120.5")
    end

    test "create_currency/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} =
               Currencies.create_currency(@invalid_attrs)
    end

    test "update_currency/2 with valid data updates the currency" do
      currency = currency_fixture()

      update_attrs = %{
        buy_price: "456.7",
        info_type: :market,
        meta: %{},
        name: "some updated name",
        price_updated_at: ~U[2023-11-09 04:55:00.718007Z],
        sell_price: "456.7",
        supplier_name: "some updated supplier_name",
        supplier_url: "some updated supplier_url",
        type: "some updated type",
        variation_percent: "456.7"
      }

      assert {:ok, %Currency{} = currency} =
               Currencies.update_currency(currency, update_attrs)

      assert currency.buy_price == Decimal.new("456.7")
      assert currency.info_type == :market
      assert currency.meta == %{}
      assert currency.name == "some updated name"
      # assert currency.price_updated_at == ~U[2023-11-09 04:55:00.718007Z]
      assert currency.sell_price == Decimal.new("456.7")
      assert currency.supplier_name == "some updated supplier_name"
      assert currency.supplier_url == "some updated supplier_url"
      assert currency.type == "some updated type"
      assert currency.variation_percent == Decimal.new("456.7")
    end

    test "update_currency/2 with invalid data returns error changeset" do
      currency = currency_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Currencies.update_currency(currency, @invalid_attrs)

      assert currency == Currencies.get_currency!(currency.id)
    end

    test "delete_currency/1 deletes the currency" do
      currency = currency_fixture()
      assert {:ok, %Currency{}} = Currencies.delete_currency(currency)

      assert_raise Ecto.NoResultsError, fn ->
        Currencies.get_currency!(currency.id)
      end
    end

    test "change_currency/1 returns a currency changeset" do
      currency = currency_fixture()
      assert %Ecto.Changeset{} = Currencies.change_currency(currency)
    end
  end
end
