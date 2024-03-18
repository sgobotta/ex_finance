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
      # # Configure topic
      # @presence_topic "presence:" <> unquote(opts)[:topic] ||
      #                   raise(
      #                     "use ExFinance.Presence expects :topic to be given"
      #                   )
      # Configure pubsub server
      @presence_pubsub_server unquote(opts)[:pubsub_server] ||
                                raise(
                                  "use ExFinance.Presence expects :pubsub_server to be given"
                                )

      # ------------------------------------------------------------------------
      # API
      #

      @doc """
      Given a `pid`, a `topic`, a `presence_id` and `meta`, calls the Presence
      module to track the process as a presence to the configured presence
      topic.
      """
      @spec track_presence(pid(), String.t(), String.t(), map()) ::
              {:ok, ref :: binary()} | {:error, reason :: term()}
      def track_presence(pid, topic, presence_id, meta),
        do: ExFinance.Presence.track(pid, topic_name(topic), presence_id, meta)

      @doc """
      Convenience function to subscribe callers to the configured presence
      topic.
      """
      @spec subscribe_presence(String.t()) :: :ok | {:error, term()}
      def subscribe_presence(topic),
        do: Phoenix.PubSub.subscribe(@presence_pubsub_server, topic_name(topic))

      @doc """
      Returns presences for the configured presence topic.
      """
      @spec list_presence(String.t()) :: Phoenix.Presence.presences()
      def list_presence(topic), do: ExFinance.Presence.list(topic_name(topic))

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
         |> handle_joins(diff.joins)}
      end

      @spec handle_joins(
              Phoenix.LiveView.Socket.t(),
              Phoenix.Presence.presences()
            ) :: Phoenix.LiveView.Socket.t()
      defp handle_joins(socket, joins) do
        Enum.reduce(joins, socket, fn {presence, %{metas: [meta | _]}},
                                      socket ->
          assign_presences(
            socket,
            Map.put(socket.assigns.presences, presence, meta)
          )
        end)
      end

      @spec handle_leaves(
              Phoenix.LiveView.Socket.t(),
              Phoenix.Presence.presences()
            ) :: Phoenix.LiveView.Socket.t()
      defp handle_leaves(socket, leaves) do
        Enum.reduce(leaves, socket, fn {presence, _metas}, socket ->
          assign_presences(
            socket,
            Map.delete(socket.assigns.presences, presence)
          )
        end)
      end

      # ------------------------------------------------------------------------
      # Assignment functions
      #
      @spec assign_presences(
              Phoenix.LiveView.Socket.t(),
              Phoenix.Presence.presences()
            ) :: Phoenix.LiveView.Socket.t()
      defp assign_presences(socket, presences \\ %{}),
        do: Phoenix.Component.assign(socket, :presences, presences)

      # ------------------------------------------------------------------------
      # Private functions
      #
      @spec topic_name(String.t()) :: Phoenix.Presence.topic()
      defp topic_name(topic), do: "presence:" <> topic
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
