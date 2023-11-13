defmodule ExFinance.Currencies do
  @moduledoc """
  The Currencies context.
  """

  import Ecto.Query, warn: false

  alias ExFinance.Repo
  alias ExFinance.Currencies.{Currency, Supplier}

  require Logger

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
    |> Enum.map(fn {currency, index} -> currency end)
  end

  defp get_order_by_type(%Currency{type: "official"}), do: 0
  defp get_order_by_type(%Currency{type: "bna"}), do: 1
  defp get_order_by_type(%Currency{type: "blue"}), do: 2
  defp get_order_by_type(%Currency{type: "crypto"}), do: 3
  defp get_order_by_type(%Currency{type: "ccl"}), do: 5
  defp get_order_by_type(%Currency{type: "mep"}), do: 6
  defp get_order_by_type(%Currency{type: "euro"}), do: 7
  defp get_order_by_type(%Currency{type: "wholesaler"}), do: 8
  defp get_order_by_type(%Currency{type: "future"}), do: 9
  defp get_order_by_type(%Currency{type: "luxury"}), do: 10
  defp get_order_by_type(%Currency{type: "tourist"}), do: 11

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

      iex> get_by_internal_id("some internal id")
      %Currency{}

      iex> get_by_internal_id("some internal id")
      nil

  """
  @spec get_by_internal_id(String.t()) :: Currency.t()
  def get_by_internal_id(internal_id) do
    Repo.get_by(Currency, internal_id: internal_id)
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
  Assigns a supplier id to the given currency.

  ## Examples

      iex> update_currency(currency, Ecto.UUID.generate())
      {:ok, %Currency{}}

      iex> update_currency(currency, "some invalid id")
      {:error, %Ecto.Changeset{}}

  """
  def assign_supplier(%Currency{} = currency, supplier_id) do
    currency
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
  def load_currency(stream_key) do
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

        changes =
          case currency.info_type do
            :reference ->
              if currency.variation_price == changes.variation_price do
                changes
              else
                Logger.debug(
                  "Updating currency with id=#{currency.id} with variation price from current_value=#{inspect(currency.variation_price)} to new_value=#{inspect(changes.variation_price)}"
                )

                changes
              end

            :market ->
              if currency.buy_price == changes.buy_price ||
                   currency.sell_price == changes.sell_price do
                changes
              else
                Logger.debug(
                  "Updating currency with id=#{currency.id} with buy price from current_buy_price=#{inspect(currency.buy_price)} to new_buy_price=#{inspect(changes.buy_price)}; and sell price from current_sell_price=#{inspect(currency.sell_price)} to new_sell_price=#{inspect(changes.sell_price)}"
                )

                changes
              end
          end

        {:ok, %Currency{} = c} = update_currency(currency, changes)
        Logger.debug("Updated currency with id=#{c.id} currency=#{inspect(c)}")
        {:ok, {:updated, c}}
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
