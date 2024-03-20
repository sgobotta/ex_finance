defmodule ExFinance.Presence do
  @moduledoc false
  use Phoenix.Presence,
    otp_app: :ex_finance,
    pubsub_server: ExFinance.PubSub

  @doc """
  Convenience function to configure a #{Phoenix.Presence} tracker for liveviews.
  A `#{Phoenix.PubSub}` implementation is used to subscribe callers to a topic
  and it's passed as an option.
  """
  @type pubsub_server_opt :: {:pubsub_server, module()}
  @type tracker_opt :: pubsub_server_opt
  @spec tracker([tracker_opt()]) :: {:__block__, list(), list()}
  def tracker(opts \\ []) do
    quote do
      import ExFinance.Presence.Client

      @presence_pubsub_server unquote(opts)[:pubsub_server] ||
                                raise(
                                  "use ExFinance.Presence expects :pubsub_server to be given"
                                )

      @callback on_presence_diff(Phoenix.LiveView.Socket.t()) ::
                  Phoenix.LiveView.Socket.t()

      # ------------------------------------------------------------------------
      # Callbacks
      #
      @impl true
      def handle_info(
            %Phoenix.Socket.Broadcast{event: "presence_diff", payload: diff},
            socket
          ) do
        {:noreply,
         socket
         |> handle_leaves(diff.leaves)
         |> handle_joins(diff.joins)
         |> on_presence_diff()}
      end

      @doc """
      Convenience function that subscribes callers to the configured presence
      topic.
      """
      @spec subscribe_presence(String.t()) :: :ok | {:error, term()}
      def subscribe_presence(topic),
        do:
          Phoenix.PubSub.subscribe(
            @presence_pubsub_server,
            presence_topic_name(topic)
          )
    end
  end

  @doc """
  When used, dispatch to the appropriate feature.
  """
  defmacro __using__({which, opts}) when is_atom(which) do
    apply(__MODULE__, which, [opts])
  end

  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
