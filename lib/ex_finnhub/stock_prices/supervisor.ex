defmodule ExFinnhub.StockPrices.Supervisor do
  @moduledoc """
  The `#{ExFinnhub.StockPrices.Supervisor}` is a module-based supervisor in
  charge of initialising any supervisor required by the Checkout context.
  """
  use Supervisor

  alias ExFinnhub.StockPrices.StockPriceSupervisor

  @spec start_link(keyword()) :: {:ok, pid()}
  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    children = [
      {Registry, keys: :unique, name: Registry.StockPriceServer},
      {StockPriceSupervisor, []}
    ]

    Supervisor.init(children, strategy: :rest_for_one)
  end
end
