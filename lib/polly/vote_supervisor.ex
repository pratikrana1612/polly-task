defmodule Polly.VoteSupervisor do
  @moduledoc """
  VoteSupervisor is a dynamic supervisor responsible for managing all the VoteManagers.
  We are using a Registry to keep track of all VoteManagers created.
  The reason for using the Registry is that this supervisor could potentially be created under a PartitionedSupervisor,
  and to fetch/find a VoteManager would become a complicated task without a Registry.
  """
  use DynamicSupervisor

  require Logger

  @registry_name Polly.VoteRegistry

  def start_link(_) do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @doc """
  Starts a VoteManager process under the Dynamic supervisor.
  It also checks if a VoteManager for the same username already exists or not.
  If it does, then nothing is done, and :ignore is returned.
  """
  @spec start_child(binary()) :: DynamicSupervisor.on_start_child()
  def start_child(username) do
    case get_pid(username) do
      nil ->
        init_arg = [username: username]
        DynamicSupervisor.start_child(__MODULE__, {Polly.VoteManager, init_arg})

      _pid ->
        :ignore
    end
  end

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  @spec get_pid(String.t()) :: pid() | nil
  defp get_pid(username) do
    case Registry.lookup(@registry_name, username) do
      [{pid, _}] -> pid
      [] -> nil
    end
  end
end
