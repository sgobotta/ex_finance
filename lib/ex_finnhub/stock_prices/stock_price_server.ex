defmodule ExFinnhub.StockPrices.StockPriceServer do
  @moduledoc """
  The StockPrice Server implementation
  """
  use GenServer, restart: :transient

  require Logger

  @interval :timer.seconds(60)
  @timeout :timer.seconds(50)

  @type symbol :: binary()
  @type state :: %{
          :do_work => (symbol() -> :ok | :error),
          :id => binary(),
          :interval => pos_integer(),
          :interval_ref => reference() | nil,
          :timeout => pos_integer(),
          :timer_ref => reference() | nil
        }

  @doc """
  Sends a heartbeat request that resets the server lifetime.
  """
  @spec heartbeat(pid) :: :ok
  def heartbeat(pid), do: GenServer.cast(pid, :heartbeat)

  @doc """
  Given a keyword of arguments, starts a #{GenServer} process linked to the
  current process.
  """
  @spec start_link(keyword()) :: {:ok, pid()}
  def start_link(init_args) do
    GenServer.start_link(__MODULE__, init_args)
  end

  @doc """
  Given a keyword of args returns a new map that represents the #{__MODULE__}
  state.
  """
  @spec initial_state(keyword()) :: state()
  def initial_state(opts) do
    %{
      do_work: Keyword.fetch!(opts, :do_work),
      id: Keyword.fetch!(opts, :id),
      interval: Keyword.get(opts, :interval, @interval),
      interval_ref: nil,
      timeout: Keyword.get(opts, :timeout, @timeout),
      timer_ref: nil
    }
  end

  @impl GenServer
  def init(init_args) do
    :ok =
      Logger.info(
        "#{__MODULE__} :: Started process with pid=#{inspect(self())}, args=#{inspect(init_args)}"
      )

    {:ok, initial_state(init_args),
     {:continue, Keyword.fetch!(init_args, :on_start)}}
  end

  @impl GenServer
  def handle_cast(:heartbeat, state) do
    {:noreply, set_timeout(state)}
  end

  @impl GenServer
  def handle_continue(on_start, state) do
    :ok = on_start.(state)

    {:noreply, do_work(state)}
  end

  @impl GenServer
  def handle_info(:work, state) do
    :ok =
      Logger.info("#{__MODULE__} :: Received work message for id=#{state.id}")

    {:noreply, do_work(state)}
  end

  @impl GenServer
  def handle_info(:kill, state) do
    :ok =
      Logger.info(
        "#{__MODULE__} :: Terminating process with pid=#{inspect(self())}"
      )

    true = Process.exit(self(), :normal)

    {:noreply, state}
  end

  defp do_work(%{do_work: do_work, id: id, interval: interval} = state) do
    :ok = do_work.(id)
    interval_ref = Process.send_after(self(), :work, interval)

    %{state | interval_ref: interval_ref}
    |> set_timeout()
  end

  defp set_timeout(%{timeout: timeout, timer_ref: nil} = state) do
    %{state | timer_ref: Process.send_after(self(), :kill, timeout)}
  end

  defp set_timeout(%{timeout: timeout, timer_ref: timer_ref} = state) do
    _timeleft = Process.cancel_timer(timer_ref)

    %{state | timer_ref: Process.send_after(self(), :kill, timeout)}
  end
end
