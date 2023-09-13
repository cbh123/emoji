defmodule Emoji.Embeddings.Worker do
  @moduledoc """
  GenServer for making embeddings out of predictions
  """
  alias Emoji.Predictions
  alias Emoji.Embeddings
  use GenServer

  @embeddings_model "daanelson/imagebind:0383f62e173dc821ec52663ed22a076d9c970549c209666ac3db181618b7a304"

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{})
  end

  def init(state) do
    schedule_creation()
    {:ok, state}
  end

  defp schedule_creation() do
    Process.send_after(self(), :work, 5000)
  end

  def handle_info(:work, state) do
    if Predictions.count_predictions_with_embeddings() < 95 do
      IO.puts("Running prediction...")
      prediction = Predictions.get_random_prediction_without_embeddings()

      embedding =
        prediction.prompt
        |> Embeddings.clean()
        |> Embeddings.create(@embeddings_model)

      {:ok, _prediction} =
        Predictions.update_prediction(prediction, %{
          embedding: embedding,
          embedding_model: @embeddings_model
        })

      schedule_creation()
    end

    {:noreply, state}
  end
end
