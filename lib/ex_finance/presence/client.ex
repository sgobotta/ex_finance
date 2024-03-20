defmodule ExFinance.Presence.Client do
  @moduledoc """
  Convenience module to implement a Presence API module for liveviews usage.
  """

  # ----------------------------------------------------------------------------
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
    do:
      ExFinance.Presence.track(
        pid,
        presence_topic_name(topic),
        presence_id,
        meta
      )

  @doc """
  Returns presences for the configured presence topic.
  """
  @spec list_presence(String.t()) :: Phoenix.Presence.presences()
  def list_presence(topic),
    do: ExFinance.Presence.list(presence_topic_name(topic))

  @doc """
  Given a presences map and a presence id, returns the total number of
  participants, excluding the given presence.
  """
  @spec count_presence_participants(
          Phoenix.Presence.presences(),
          Phoenix.Presence.presence()
        ) :: non_neg_integer()
  def count_presence_participants(presences, current_presence) do
    presences
    |> Map.delete(current_presence)
    |> Map.keys()
    |> length
  end

  # ----------------------------------------------------------------------------
  # Handlers
  #

  @doc """
  Given a presence diff updates presences with participants that joined.
  """
  @spec handle_joins(
          Phoenix.LiveView.Socket.t(),
          Phoenix.Presence.presences()
        ) :: Phoenix.LiveView.Socket.t()
  def handle_joins(socket, joins) do
    Enum.reduce(joins, socket, fn {presence, %{metas: [meta | _]}}, socket ->
      assign_presences(
        socket,
        Map.put(socket.assigns.presences, presence, meta)
      )
    end)
  end

  @doc """
  Given a presence diff updates presences with participants that left.
  """
  @spec handle_leaves(
          Phoenix.LiveView.Socket.t(),
          Phoenix.Presence.presences()
        ) :: Phoenix.LiveView.Socket.t()
  def handle_leaves(socket, leaves) do
    Enum.reduce(leaves, socket, fn {presence, _metas}, socket ->
      assign_presences(
        socket,
        Map.delete(socket.assigns.presences, presence)
      )
    end)
  end

  # ----------------------------------------------------------------------------
  # Assignment functions
  #

  @doc """
  Assigns presences to the given socket.
  """
  @spec assign_presences(
          Phoenix.LiveView.Socket.t(),
          Phoenix.Presence.presences()
        ) :: Phoenix.LiveView.Socket.t()
  def assign_presences(socket, presences \\ %{}),
    do: Phoenix.Component.assign(socket, :presences, presences)

  @doc """
  Assigns total number of presences to the given socket.
  """
  @spec assign_participants(
          Phoenix.LiveView.Socket.t(),
          Phoenix.Presence.presence()
        ) ::
          Phoenix.LiveView.Socket.t()
  def assign_participants(socket, current_presence),
    do:
      Phoenix.Component.assign(
        socket,
        :presence_participants,
        count_presence_participants(socket.assigns.presences, current_presence)
      )

  # ----------------------------------------------------------------------------
  # Helper functions
  #

  @doc """
  Given a topic, returns a prefixed string representing a presence topic.
  """
  @spec presence_topic_name(String.t()) :: Phoenix.Presence.topic()
  def presence_topic_name(topic), do: "presence:" <> topic
end
