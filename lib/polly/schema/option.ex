defmodule Polly.Schema.Option do
  @moduledoc """
  Represents an option associated with a poll, containing the option text and the number of votes.
  """
  use Ecto.Schema

  import Ecto.Changeset
  import Ecto.UUID, only: [generate: 0]

  alias Polly.Schema.Option

  @type t :: %__MODULE__{
          text: String.t(),
          votes: integer()
        }

  embedded_schema do
    field(:text, :string)
    field(:votes, :integer, default: 0)
    # field(:binary_id, autogenerate: true)
  end

  @doc """
  Creates a changeset for an `Option` struct, ensuring the presence of text
  and initializing the votes count to 0 if not provided.
  """
  def changeset(%Option{} = option, attrs \\ %{}) do
    option
    |> cast(attrs, [:text, :votes])
    |> validate_required([:text])
    |> validate_length(:text, min: 1)
    |> put_id()
  end

  defp put_id(%Ecto.Changeset{valid?: true} = changeset) do
    change(changeset, id: generate())
  end

  defp put_id(%Ecto.Changeset{valid?: false} = changeset) do
    changeset
  end
end
