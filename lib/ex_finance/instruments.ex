defmodule ExFinance.Instruments do
  @moduledoc """
  The Instruments context.
  """

  import Ecto.Query, warn: false
  alias ExFinance.Repo

  alias ExFinance.Currencies.Supplier
  alias ExFinance.Instruments.{Cedear, CedearPriceCalc}

  require Logger

  # ----------------------------------------------------------------------------
  # Stocks business
  #

  @spec fetch_stock_price_by_cedear(Cedear.t()) :: ExFinnhub.StockPrice.t()
  def fetch_stock_price_by_cedear(%Cedear{symbol: symbol}) do
    case ExFinnhub.StockPrice.quote(symbol) do
      {:ok, %ExFinnhub.StockPrice{} = stock_price} ->
        stock_price

      :error ->
        :error
    end
  end

  # ----------------------------------------------------------------------------
  # Cedear business
  #

  def change_cedear_price_calc(
        %CedearPriceCalc{} = cedear_price_calc,
        attrs \\ %{}
      ) do
    CedearPriceCalc.changeset(cedear_price_calc, attrs)
  end

  @spec get_average_stock_price(
          Cedear.t(),
          ExFinance.Currencies.Currency.t(),
          Decimal.t()
        ) :: Decimal.t()
  def get_average_stock_price(
        %Cedear{ratio: ratio},
        %ExFinance.Currencies.Currency{variation_price: variation_price},
        cedear_price
      ) do
    Decimal.div(Decimal.mult(cedear_price, ratio), variation_price)
    |> Decimal.round(2)
  end

  # ----------------------------------------------------------------------------
  # Cedear cache management
  #

  @doc """
  Fetches data from redis to perform some checks before storing or updating the
  cedears table.
  """
  def load_cedear_entry(stream_key) do
    with %Redis.Stream.Entry{} = entry <- fetch_last_cedear_entry(stream_key),
         %Ecto.Changeset{valid?: true} = cs <- Cedear.from_entry!(entry) do
      case upsert_cedear(cs) do
        {:ok, {:updated, p}} ->
          Logger.debug("Updated cedear=#{inspect(p)}")
          # Trace updated cedear
          {:ok, p}

        {:ok, {:created, p}} ->
          Logger.debug("Created cedear=#{inspect(p)}")
          # Trace new added cedear
          {:ok, p}
      end
    else
      %Ecto.Changeset{valid?: false} = cs ->
        Logger.error(
          "An error occured while casting stream values into Cedear changeset=#{inspect(cs)}"
        )

        {:error, :invalid_values}

      error ->
        error
    end
  end

  @doc """
  Atomically inserts or updates a cedear record whether an entity is persisted
  or not. Then a Supplier existance is checked to finally relate the cedear to
  the resulting supplier.
  """
  @spec upsert_cedear(Ecto.Changeset.t()) :: any()
  def upsert_cedear(cs) do
    symbol = Ecto.Changeset.get_field(cs, :symbol)

    Ecto.Multi.new()
    # Checks cedear existance
    |> Ecto.Multi.one(:cedear, fn _multi ->
      from(c in Cedear, where: c.symbol == ^symbol)
    end)
    # Create or Update cedear
    |> Ecto.Multi.run(:maybe_create_cedear, fn
      _repo, %{cedear: nil} = _multi ->
        {:ok, %Cedear{} = p} = create_cedear(cs.changes)
        {:ok, {:created, p}}

      _repo, %{cedear: %Cedear{} = cedear} = _multi ->
        changes = cs.changes

        cedear =
          if cedear.ratio == changes.ratio do
            cedear
          else
            Logger.debug(
              "Updating cedear with id=#{cedear.id} with ratio from ratio=#{inspect(cedear.ratio)} to ratio=#{inspect(changes.ratio)}"
            )

            {:ok, %Cedear{} = cedear} = update_cedear(cedear, changes)

            cedear
          end

        {:ok, {:updated, cedear}}
    end)
    # Check supplier existance
    |> Ecto.Multi.one(:supplier, fn %{
                                      maybe_create_cedear:
                                        {cedear_op,
                                         %Cedear{
                                           supplier_name: supplier_name
                                         }}
                                    }
                                    when cedear_op in [:created, :updated] ->
      from(s in Supplier, where: s.name == ^supplier_name)
    end)
    # Create or update Supplier
    |> Ecto.Multi.run(:maybe_create_supplier, fn
      _repo,
      %{
        maybe_create_cedear:
          {_cedear_op, %Cedear{supplier_name: supplier_name}},
        supplier: nil
      } ->
        {:ok, %Supplier{} = s} =
          ExFinance.Currencies.create_supplier(%{name: supplier_name})

        {:ok, {:created, s}}

      _repo, %{supplier: %Supplier{} = s} ->
        {:ok, {:noop, s}}
    end)
    # Relate supplier to a cedear
    |> Ecto.Multi.run(:assoc_supplier, fn _repo,
                                          %{
                                            maybe_create_cedear:
                                              {_cedear_op, %Cedear{} = c},
                                            maybe_create_supplier:
                                              {_supplier_op,
                                               %Supplier{id: supplier_id}}
                                          } ->
      {:ok, %Cedear{}} = ExFinance.Currencies.assign_supplier(c, supplier_id)
      {:ok, {:ok, :noop}}
    end)
    # Submit transaction
    |> Repo.transaction()
    |> case do
      {:ok, result} ->
        {:ok, result.maybe_create_cedear}

      error ->
        Logger.error(
          "There was an error while processing a cedear, upsert error=#{inspect(error, pretty: true)}"
        )

        error
    end
  end

  @spec fetch_last_cedear_entry(binary, non_neg_integer() | String.t()) ::
          Redis.Stream.Entry.t() | list() | any()
  def fetch_last_cedear_entry(stream_key, _count \\ "*") do
    stream_name = get_stream_name("cedear-history_" <> stream_key)

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

  # ----------------------------------------------------------------------------
  # Database access & management
  #

  @doc """
  Returns a list of cedears that match the given query.

  ## Examples

      iex> search_cedear("some name")
      [%Cedear{}, ...]

  """
  def search_cedear(search_query) do
    search_query = "%#{search_query}%"

    Cedear
    |> order_by(asc: :symbol)
    |> where(
      [c],
      ilike(c.name, ^search_query) or ilike(c.symbol, ^search_query)
    )
    |> limit(5)
    |> Repo.all()
  end

  @doc """
  Returns the list of cedears.

  ## Examples

      iex> list_cedears()
      [%Cedear{}, ...]

  """
  def list_cedears do
    Repo.all(Cedear)
  end

  @doc """
  Gets a single cedear.

  Raises `Ecto.NoResultsError` if the Cedear does not exist.

  ## Examples

      iex> get_cedear!(123)
      %Cedear{}

      iex> get_cedear!(456)
      ** (Ecto.NoResultsError)

  """
  def get_cedear!(id), do: Repo.get!(Cedear, id)

  @doc """
  Creates a cedear.

  ## Examples

      iex> create_cedear(%{field: value})
      {:ok, %Cedear{}}

      iex> create_cedear(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_cedear(attrs \\ %{}) do
    %Cedear{}
    |> Cedear.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a cedear.

  ## Examples

      iex> update_cedear(cedear, %{field: new_value})
      {:ok, %Cedear{}}

      iex> update_cedear(cedear, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_cedear(%Cedear{} = cedear, attrs) do
    cedear
    |> Cedear.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a cedear.

  ## Examples

      iex> delete_cedear(cedear)
      {:ok, %Cedear{}}

      iex> delete_cedear(cedear)
      {:error, %Ecto.Changeset{}}

  """
  def delete_cedear(%Cedear{} = cedear) do
    Repo.delete(cedear)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking cedear changes.

  ## Examples

      iex> change_cedear(cedear)
      %Ecto.Changeset{data: %Cedear{}}

  """
  def change_cedear(%Cedear{} = cedear, attrs \\ %{}) do
    Cedear.changeset(cedear, attrs)
  end
end
