defmodule Polly.PollsManager do
  @moduledoc """
  PollsManager takes care of all the state related to Polls.
  """
  alias Polly.Schema.Poll

  @polls :polls
  @polls_votes :polls_votes
  @polls_options_votes :polls_options_votes

  @doc """
  Creates all the ets tables needed for functioning of the polls manager
  """
  def init() do
    :ets.new(@polls, [
      :named_table,
      :public,
      :set,
      {:write_concurrency, true},
      {:read_concurrency, true}
    ])

    :ets.new(@polls_votes, [
      :named_table,
      :public,
      :set,
      {:write_concurrency, true},
      {:read_concurrency, true}
    ])

    :ets.new(@polls_options_votes, [
      :named_table,
      :public,
      :set,
      {:write_concurrency, true},
      {:read_concurrency, true}
    ])
  end

  @doc """
  Inserts the poll in the @polls ets table with id as the key. Also adds an entry in the @polls_votes table
  for total votes as 0.
  """
  @spec add_poll(Poll.t()) :: :ok | {:error, :nil_poll_id}
  def add_poll(%Poll{id: nil}), do: {:error, :nil_poll_id}

  def add_poll(%Poll{id: poll_id} = poll) do
    :ets.insert(@polls, {poll_id, poll})
    :ets.insert(@polls_votes, {poll_id, 0})
    :ok
  end

  @doc """
  Increments the total vote counter for the poll and the option vote counter which is
  meant to keep track of votes per option.
  """
  @spec incr_vote!(binary(), binary()) :: :ok | {:error, atom()}
  def incr_vote!(poll_id, option_id) when is_binary(poll_id) and is_binary(option_id) do
    case has_option?(poll_id, option_id) do
      true ->
        :ets.update_counter(@polls_votes, poll_id, {2, 1})
        :ets.update_counter(@polls_options_votes, option_id, {2, 1})
        :ok

      false ->
        {:error, :invalid_option}
    end
  end

  @doc """
  Lists all the polls from the underlying ets table
  """
  @spec list_polls_with_ids :: Keyword.t()
  def list_polls_with_ids() do
    :ets.tab2list(@polls)
    |> Enum.map(fn {id, poll} -> {id, poll} end)
  end

  @doc """
  Retrieves a poll by id, optionally including the vote counts for each option.
  """
  @spec get_poll!(binary(), boolean()) :: Poll.t()
  def get_poll!(poll_id, with_option_votes \\ false) do
    case :ets.lookup(@polls, poll_id) do
      [{^poll_id, poll}] ->
        poll
        |> replace_option_votes(with_option_votes)

      [] ->
        {:error, :poll_not_found}
    end
  end

  # Private functions

  defp get_poll_votes!(poll_id) do
    case :ets.lookup(@polls_votes, poll_id) do
      [{^poll_id, count}] -> count
      [] -> {:error, :poll_not_found}
    end
  end

  defp replace_option_votes(poll, true) do
    updated_options =
      Enum.map(poll.options, fn option ->
        Map.replace(option, :votes, safe_lookup_element(option.id))
      end)

    Map.replace(poll, :options, updated_options)
  end

  defp replace_option_votes(poll, false) do
    poll
  end

  defp has_option?(poll_id, option_id) do
    case :ets.lookup(@polls, poll_id) do
      [{^poll_id, poll}] ->
        Enum.any?(poll.options, fn option -> option.id == option_id end)

      [] ->
        false
    end
  end

  defp safe_lookup_element(option_id) do
    case :ets.lookup(@polls_options_votes, option_id) do
      [{^option_id, count}] -> count
      [] -> 0
    end
  end
end
