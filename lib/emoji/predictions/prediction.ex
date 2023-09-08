defmodule Emoji.Predictions.Prediction do
  use Ecto.Schema
  import Ecto.Changeset

  schema "predictions" do
    field :no_bg_output, :string
    field :emoji_output, :string
    field :prompt, :string
    field :uuid, :string
    field :score, :integer, default: 0
    field :count_votes, :integer, default: 0
    field :is_featured, Ecto.Enum, values: [true, false]

    timestamps()
  end

  @doc false
  def changeset(prediction, attrs) do
    prediction
    |> cast(attrs, [
      :uuid,
      :prompt,
      :no_bg_output,
      :emoji_output,
      :score,
      :count_votes,
      :is_featured
    ])
    |> validate_required([:prompt])
  end
end
