defmodule ExFinance.Currencies do
  @moduledoc """
  The Currencies context.
  """

  import Ecto.Query, warn: false

  alias ExFinance.Currencies.Channels
  alias ExFinance.Currencies.{Currency, Supplier}
  alias ExFinance.Repo

  alias Redis.Stream

  require Logger

  @type interval :: :daily | :weekly | :monthly

  ## Events

  @doc """
  Subscribe to the currencies topic
  """
  @spec subscribe_currencies :: :ok
  def subscribe_currencies, do: Channels.subscribe_currencies_topic()

  @doc """
  Returns the list of currencies.

  ## Examples

      iex> list_currencies()
      [%Currency{}, ...]

  """
  def list_currencies do
    Repo.all(Currency)
  end

  @doc """
  Returns a sorted list of currencies.

  ## Examples

      iex> sort_currencies()
      [%Currency{}, ...]

  """
  def sort_currencies(currencies) do
    Enum.with_index(currencies, fn currency, _index ->
      {currency, get_order_by_type(currency)}
    end)
    |> Enum.sort(fn {_previous, previous_index}, {_next, next_index} ->
      previous_index <= next_index
    end)
    |> Enum.map(fn {currency, _index} -> currency end)
  end

  @doc """
  Returns a priority specification for each currency type. This is used to
  render currencies in a particular order.
  """
  @spec get_order_by_type(Currency.t()) :: integer()
  def get_order_by_type(%Currency{type: "official"}), do: 0
  def get_order_by_type(%Currency{type: "bna"}), do: 1
  def get_order_by_type(%Currency{type: "blue"}), do: 2
  def get_order_by_type(%Currency{type: "crypto"}), do: 3
  def get_order_by_type(%Currency{type: "ccl"}), do: 5
  def get_order_by_type(%Currency{type: "mep"}), do: 6
  def get_order_by_type(%Currency{type: "euro"}), do: 7
  def get_order_by_type(%Currency{type: "wholesaler"}), do: 8
  def get_order_by_type(%Currency{type: "future"}), do: 9
  def get_order_by_type(%Currency{type: "luxury"}), do: 10
  def get_order_by_type(%Currency{type: "tourist"}), do: 11
  def get_order_by_type(%Currency{type: _}), do: -1

  def list_product_categories do
    Repo.all(from(p in Currency, select: p.category, distinct: p.category))
  end

  def list_product_supplier do
    Repo.all(
      from(p in Currency, select: p.supplier_name, distinct: p.supplier_name)
    )
  end

  @doc """
  Gets a single currency.

  Raises `Ecto.NoResultsError` if the Currency does not exist.

  ## Examples

      iex> get_currency!(123)
      %Currency{}

      iex> get_currency!(456)
      ** (Ecto.NoResultsError)

  """
  def get_currency!(id), do: Repo.get!(Currency, id)

  @doc """
  Given an internal id returns a currency if exists.

    ## Examples

      iex> get_by_type("some internal id")
      %Currency{}

      iex> get_by_type("some internal id")
      nil

  """
  @spec get_by_type(String.t()) :: Currency.t()
  def get_by_type(type) do
    Repo.get_by(Currency, type: type)
  end

  @doc """
  Creates a currency.

  ## Examples

      iex> create_currency(%{field: value})
      {:ok, %Currency{}}

      iex> create_currency(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_currency(attrs \\ %{}) do
    %Currency{}
    |> Currency.changeset(attrs)
    # |> Ecto.Changeset.put_change(
    #   :price_updated_at,
    #   DateTime.truncate(DateTime.utc_now(), :second)
    # )
    |> Repo.insert()
  end

  @doc """
  Updates a currency.

  ## Examples

      iex> update_currency(currency, %{field: new_value})
      {:ok, %Product{}}

      iex> update_currency(currency, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_currency(%Currency{} = currency, attrs) do
    currency
    |> Currency.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a currency.

  ## Examples

      iex> delete_currency(currency)
      {:ok, %Currency{}}

      iex> delete_currency(currency)
      {:error, %Ecto.Changeset{}}

  """
  def delete_currency(%Currency{} = currency) do
    Repo.delete(currency)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking currency changes.

  ## Examples

      iex> change_currency(currency)
      %Ecto.Changeset{data: %Currency{}}

  """
  def change_currency(%Currency{} = currency, attrs \\ %{}) do
    Currency.changeset(currency, attrs)
  end

  @doc """
  Assigns a supplier id to the given entity.

  ## Examples

      iex> update_currency(currency, Ecto.UUID.generate())
      {:ok, %Currency{}}

      iex> update_currency(cedear, Ecto.UUID.generate())
      {:ok, %ExFinance.Instruments.Cedear{}}

      iex> update_currency(currency, "some invalid id")
      {:error, %Ecto.Changeset{}}

  """
  def assign_supplier(entity, supplier_id) do
    entity
    |> Currency.change_supplier(supplier_id)
    |> Repo.update()
  end

  # ----------------------------------------------------------------------------
  # Currency cache management
  #

  @doc """
  Fetches data from redis to perform some checks before storing or updating the
  currencies table.
  """
  def load_currency_entry(stream_key) do
    with %Redis.Stream.Entry{} = entry <- fetch_last_currency_entry(stream_key),
         %Ecto.Changeset{valid?: true} = cs <- Currency.from_entry!(entry) do
      case upsert_currency(cs) do
        {:ok, {:updated, p}} ->
          Logger.debug("Updated currency currency=#{inspect(p)}")
          # Trace updated currency
          {:ok, p}

        {:ok, {:created, p}} ->
          Logger.debug("Created currency currency=#{inspect(p)}")
          # Trace new added currency
          {:ok, p}
      end
    else
      %Ecto.Changeset{valid?: false} = cs ->
        Logger.error(
          "An error occured while casting stream values into Currency changeset=#{inspect(cs)}"
        )

        {:error, :invalid_values}

      error ->
        error
    end
  end

  @doc """
  Atomically inserts or updates a currency record whether an entity is persisted
  or not. Then a Supplier existance is checked to finally relate the currency to
  the resulting supplier.
  """
  @spec upsert_currency(Ecto.Changeset.t()) :: any()
  def upsert_currency(cs) do
    type = Ecto.Changeset.get_field(cs, :type)

    Ecto.Multi.new()
    # Checks currency existance
    |> Ecto.Multi.one(:currency, fn _multi ->
      from(c in Currency, where: c.type == ^type)
    end)
    # Create or Update currency
    |> Ecto.Multi.run(:maybe_create_currency, fn
      _repo, %{currency: nil} = _multi ->
        {:ok, %Currency{} = p} = create_currency(cs.changes)
        {:ok, {:created, p}}

      _repo, %{currency: %Currency{} = currency} = _multi ->
        changes = cs.changes

        currency =
          case currency.info_type do
            :reference ->
              if currency.variation_price == changes.variation_price do
                currency
              else
                Logger.debug(
                  "Updating currency with id=#{currency.id} with variation price from current_value=#{inspect(currency.variation_price)} to new_value=#{inspect(changes.variation_price)}"
                )

                {:ok, %Currency{} = currency} =
                  update_currency(currency, changes)

                currency
              end

            :market ->
              if currency.buy_price == changes.buy_price &&
                   currency.sell_price == changes.sell_price do
                currency
              else
                Logger.debug(
                  "Updating currency with id=#{currency.id} with buy price from current_buy_price=#{inspect(currency.buy_price)} to new_buy_price=#{inspect(changes.buy_price)}; and sell price from current_sell_price=#{inspect(currency.sell_price)} to new_sell_price=#{inspect(changes.sell_price)}"
                )

                {:ok, %Currency{} = currency} =
                  update_currency(currency, changes)

                currency
              end
          end

        {:ok, {:updated, currency}}
    end)
    # Check supplier existance
    |> Ecto.Multi.one(:supplier, fn %{
                                      maybe_create_currency:
                                        {currency_op,
                                         %Currency{
                                           supplier_name: supplier_name
                                         }}
                                    }
                                    when currency_op in [:created, :updated] ->
      from(s in Supplier, where: s.name == ^supplier_name)
    end)
    # Create or update Supplier
    |> Ecto.Multi.run(:maybe_create_supplier, fn
      _repo,
      %{
        maybe_create_currency:
          {_currency_op, %Currency{supplier_name: supplier_name}},
        supplier: nil
      } ->
        {:ok, %Supplier{} = s} = create_supplier(%{name: supplier_name})
        {:ok, {:created, s}}

      _repo, %{supplier: %Supplier{} = s} ->
        {:ok, {:noop, s}}
    end)
    # Relate supplier to a currency
    |> Ecto.Multi.run(:assoc_supplier, fn _repo,
                                          %{
                                            maybe_create_currency:
                                              {_currency_op, %Currency{} = c},
                                            maybe_create_supplier:
                                              {_supplier_op,
                                               %Supplier{id: supplier_id}}
                                          } ->
      {:ok, %Currency{}} = assign_supplier(c, supplier_id)
      {:ok, {:ok, :noop}}
    end)
    # Submit transaction
    |> Repo.transaction()
    |> case do
      {:ok, result} ->
        {:ok, result.maybe_create_currency}

      error ->
        Logger.error(
          "There was an error while processing a currency upsert error=#{inspect(error, pretty: true)}"
        )

        error
    end
  end

  @spec fetch_last_currency_entry(binary, non_neg_integer() | String.t()) ::
          Redis.Stream.Entry.t() | list() | any()
  def fetch_last_currency_entry(stream_key, _count \\ "*") do
    stream_name = get_stream_name("currency-history_" <> stream_key)

    case Redis.Client.fetch_last_stream_entry(stream_name) do
      {:ok, %Redis.Stream.Entry{} = entry} ->
        entry

      error ->
        Logger.error(
          "An error occured while fetching last product entry from redis for stream_key=#{stream_name}."
        )

        error
    end
  end

  @doc """
  Given a supplier name and a type for a currency, returns a list of redis
  stream entries for all the avaialble historical data.
  """
  @spec fetch_currency_history(String.t(), String.t()) ::
          {:ok, [Redis.Stream.Entry.t()]} | :error
  def fetch_currency_history(supplier_name, type, interval \\ :daily) do
    stream_name =
      get_stream_name("currency-history_" <> supplier_name <> "_" <> type)

    before_now = look_into_the_past(-20, interval)

    since =
      DateTime.utc_now()
      |> DateTime.add(before_now, :day)
      |> DateTime.to_unix(:millisecond)

    with {:ok, entries} <-
           Redis.Client.fetch_reverse_stream_since(stream_name, since),
         filtered_entries <- filter_history_entries(entries, interval),
         history <- map_currency_history(filtered_entries) do
      {:ok, history}
    else
      error ->
        Logger.error(
          "An error occured while fetching currency history from redis for supplier_name=#{supplier_name} type=#{type} error=#{inspect(error)}"
        )

        :error
    end
  rescue
    error ->
      Logger.error(
        "Recovered from an while fetching currency history from redis error=#{inspect(error)}"
      )

      :error
  end

  @spec look_into_the_past(integer(), atom()) :: integer()
  defp look_into_the_past(days, :daily), do: days
  defp look_into_the_past(days, :monthly), do: days * 30
  defp look_into_the_past(days, :weekly), do: days * 7

  @spec filter_history_entries([Redis.Stream.Entry.t()], atom()) :: [
          Redis.Stream.Entry.t()
        ]
  defp filter_history_entries(entries, interval) do
    entries
    |> group_history_by(interval)
    |> Enum.map(fn {_datetime, entries} ->
      entries
      |> Enum.sort_by(
        &DateTime.to_date(Stream.Entry.get_datetime(&1)),
        {:desc, Date}
      )
      |> hd()
    end)
    |> Enum.sort_by(
      &DateTime.to_date(Stream.Entry.get_datetime(&1)),
      {:asc, Date}
    )
  end

  @spec group_history_by([Redis.Stream.Entry.t()], interval()) :: map()
  defp group_history_by(entries, :daily) do
    entries
    |> Enum.group_by(&DateTime.to_date(Stream.Entry.get_datetime(&1)))
  end

  defp group_history_by(entries, :monthly) do
    entries
    |> Enum.group_by(fn %Stream.Entry{} = entry ->
      Stream.Entry.get_datetime(entry)
      |> DateTime.to_date()
      |> Date.beginning_of_month()
    end)
  end

  defp group_history_by(entries, :weekly) do
    entries
    |> Enum.group_by(fn %Stream.Entry{} = entry ->
      Stream.Entry.get_datetime(entry)
      |> DateTime.to_date()
      |> Date.beginning_of_week()
    end)
  end

  @spec map_currency_history([Redis.Stream.Entry.t()]) :: [
          {NaiveDateTime.t(), Currency.t()}
        ]
  defp map_currency_history(entries) do
    Enum.map(entries, fn %Redis.Stream.Entry{datetime: datetime} = entry ->
      %Currency{} =
        currency =
        entry
        |> Currency.from_entry!()
        |> Ecto.Changeset.apply_changes()

      {datetime, currency}
    end)
  end

  defp get_stream_name(stream_key), do: "#{get_stage()}_stream_#{stream_key}_v1"

  defp get_stage, do: ExFinance.Application.stage()

  @doc """
  Returns the list of suppliers.

  ## Examples

      iex> list_suppliers()
      [%Supplier{}, ...]

  """
  def list_suppliers do
    Repo.all(Supplier)
  end

  @doc """
  Gets a single supplier.

  Raises `Ecto.NoResultsError` if the Supplier does not exist.

  ## Examples

      iex> get_supplier!(123)
      %Supplier{}

      iex> get_supplier!(456)
      ** (Ecto.NoResultsError)

  """
  def get_supplier!(id), do: Repo.get!(Supplier, id)

  @doc """
  Creates a supplier.

  ## Examples

      iex> create_supplier(%{field: value})
      {:ok, %Supplier{}}

      iex> create_supplier(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_supplier(attrs \\ %{}) do
    %Supplier{}
    |> Supplier.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a supplier.

  ## Examples

      iex> update_supplier(supplier, %{field: new_value})
      {:ok, %Supplier{}}

      iex> update_supplier(supplier, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_supplier(%Supplier{} = supplier, attrs) do
    supplier
    |> Supplier.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a supplier.

  ## Examples

      iex> delete_supplier(supplier)
      {:ok, %Supplier{}}

      iex> delete_supplier(supplier)
      {:error, %Ecto.Changeset{}}

  """
  def delete_supplier(%Supplier{} = supplier) do
    Repo.delete(supplier)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking supplier changes.

  ## Examples

      iex> change_supplier(supplier)
      %Ecto.Changeset{data: %Supplier{}}

  """
  def change_supplier(%Supplier{} = supplier, attrs \\ %{}) do
    Supplier.changeset(supplier, attrs)
  end
end
