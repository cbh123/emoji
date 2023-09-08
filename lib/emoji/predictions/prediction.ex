defmodule Emoji.Predictions.Prediction do
  use Ecto.Schema
  import Ecto.Changeset

  schema "predictions" do
    field :output, :string
    field :prompt, :string
    field :uuid, :string
    field :score, :integer, default: 0
    field :count_votes, :integer, default: 0

    timestamps()
  end

  @doc false
  def changeset(prediction, attrs) do
    prediction
    |> cast(attrs, [:uuid, :prompt, :output, :score, :count_votes])
    |> validate_required([:prompt])
  end
end
