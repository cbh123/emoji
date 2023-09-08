defmodule Emoji.Predictions.Prediction do
  use Ecto.Schema
  import Ecto.Changeset

  schema "predictions" do
    field :output, :string
    field :prompt, :string
    field :uuid, :string

    timestamps()
  end

  @doc false
  def changeset(prediction, attrs) do
    prediction
    |> cast(attrs, [:uuid, :prompt, :output])
    |> validate_required([:prompt])
  end
end
