defmodule Polly.Polls do
  @moduledoc """
  This module holds functions related to CRUD operations for Polls.
  """
  alias Polly.Schema.Poll
  alias Polly.PollsManager

  def list_polls() do
    PollsManager.list_polls_with_ids()
  end

  @spec get_poll(binary(), boolean()) :: Poll.t() | nil
  def get_poll(poll_id, with_option_votes \\ false) do
    try do
      PollsManager.get_poll!(poll_id, with_option_votes)
    rescue
      ArgumentError ->
        nil
    end
  end

  @spec change_poll(%Poll{}) :: Ecto.Changeset.t()

  def change_poll(%Poll{} = poll, attrs \\ %{}) do
    Poll.changeset(poll, attrs)
  end

  @spec create_poll(map()) :: {:ok, Poll.t()} | {:error, Ecto.Changeset.t()}
  def create_poll(params) do
    %Poll{}
    |> Poll.changeset(params)
    |> Ecto.Changeset.apply_action(:insert)
    |> do_create_poll()
  end

  defp do_create_poll({:ok, %Poll{} = poll}) do
    case PollsManager.add_poll(poll) do
      :ok -> {:ok, poll}
      {:error, :nil_poll_id} -> {:error, "Poll ID cannot be nil"}
    end
  end

  defp do_create_poll({:error, changeset}) do
    {:error, changeset}
  end
end
