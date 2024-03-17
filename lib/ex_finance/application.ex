defmodule ExFinance.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  alias ExFinance.Currencies.CurrencyProducer
  alias ExFinance.Instruments.CedearProducer

  @type env :: :dev | :test | :prod
  @type stage :: :local | :dev

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      ExFinanceWeb.Telemetry,
      # Start the Redis service
      Redis,
      # Start the Ecto repository
      ExFinance.Repo,
      {DNSCluster,
       query: Application.get_env(:ex_finance, :dns_cluster_query) || :ignore},
      # Start the PubSub system
      {Phoenix.PubSub, name: ExFinance.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: ExFinance.Finch},
      # Start a worker by calling: ExFinance.Worker.start_link(arg)
      # {ExFinance.Worker, arg},
      CurrencyProducer.child_spec(
        supplier: fetch_currency_supplier(),
        module_name: fetch_currency_supplier_producer_name()
      ),
      CedearProducer.child_spec(
        supplier: fetch_cedear_supplier(),
        module_name: fetch_cedear_supplier_producer_name()
      ),
      # Start to serve requests, typically the last entry
      ExFinanceWeb.Endpoint,
      # Start StockPrices supervisor
      ExFinnhub.StockPrices,
      # Start Presence supervisor
      ExFinance.Presence
      # {ExFinnhub.StockPrices.Producer,
      #  [counter: 5, name: ExFinnhub.StockPrices.Producer]}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ExFinance.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ExFinanceWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  @spec env :: env()
  def env, do: Application.fetch_env!(:ex_finance, :environment)

  @spec stage :: stage()
  def stage, do: Application.fetch_env!(:ex_finance, :stage)

  defp fetch_currency_supplier, do: System.fetch_env!("CURRENCY_SUPPLIER")

  defp fetch_cedear_supplier, do: System.fetch_env!("CEDEAR_SUPPLIER")

  defp fetch_currency_supplier_producer_name,
    do: System.fetch_env!("CURRENCY_SUPPLIER_PRODUCER_NAME")

  defp fetch_cedear_supplier_producer_name,
    do: System.fetch_env!("CEDEAR_SUPPLIER_PRODUCER_NAME")

  def fetch_finnhub_config!, do: Application.fetch_env!(:ex_finance, ExFinnhub)
end
