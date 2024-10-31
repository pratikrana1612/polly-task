defmodule Polly.Schema.Poll do
  @moduledoc """
  Represents a Poll struct
  """
  use Ecto.Schema

  alias Polly.Schema.Poll
  alias Polly.Schema.Option

  import Ecto.Changeset

  @type t :: %__MODULE__{}

  embedded_schema do
    field(:title, :string)
    field(:description, :string)
    field(:total_votes, :integer, default: 0)
    field(:creator_username, :string)
    field(:created_at, :naive_datetime)
    embeds_many(:options, Option, on_replace: :delete)
  end

  @doc """
  Creates a changeset based on the given poll and attributes.

  ## Params
  - `poll` (Poll struct): The poll to be updated.
  - `attrs` (map): Attributes to update the poll with.
  """
  def changeset(%Poll{} = poll, attrs \\ %{}) do
    poll
    |> cast(attrs, [:title, :description, :creator_username, :total_votes])
    |> validate_required([:title, :creator_username])
    |> validate_length(:title, min: 3)
    |> validate_number(:total_votes, greater_than_or_equal_to: 0)
    |> cast_embed(:options)
    |> put_id()
    |> put_created_at()
  end

  # Assigns a unique ID to the poll.
  defp put_id(%Ecto.Changeset{valid?: true} = changeset) do
    change(changeset, %{id: Ecto.UUID.generate()})
  end

  defp put_id(%Ecto.Changeset{valid?: false} = changeset) do
    changeset
  end

  # Sets the current timestamp for the `created_at` field if it's nil.
  defp put_created_at(%Ecto.Changeset{valid?: true} = changeset) do
    case get_field(changeset, :created_at) do
      nil -> change(changeset, %{created_at: NaiveDateTime.utc_now()})
      _ -> changeset
    end
  end

  defp put_created_at(%Ecto.Changeset{valid?: false} = changeset) do
    changeset
  end
end
