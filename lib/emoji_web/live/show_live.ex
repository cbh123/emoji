defmodule EmojiWeb.ShowLive do
  use EmojiWeb, :live_view
  alias Emoji.Predictions

  def mount(%{"id" => id}, _session, socket) do
    prediction = Predictions.get_prediction!(id)
    {:ok, socket |> assign(prediction: prediction)}
  end

  def handle_event("thumbs-up", %{"id" => id}, socket) do
    prediction = Predictions.get_prediction!(id)

    {:ok, _prediction} =
      Predictions.update_prediction(prediction, %{
        score: prediction.score + 1,
        count_votes: prediction.count_votes + 1
      })

    {:noreply, socket |> put_flash(:info, "Thanks for your rating!")}
  end

  def handle_event("thumbs-down", %{"id" => id}, socket) do
    prediction = Predictions.get_prediction!(id)

    {:ok, _prediction} =
      Predictions.update_prediction(prediction, %{
        score: prediction.score - 1,
        count_votes: prediction.count_votes + 1
      })

    {:noreply, socket |> put_flash(:info, "Thanks for your rating!")}
  end

  defp human_name(name) do
    dasherize(name)
  end

  defp dasherize(name) do
    name
    |> String.replace("A TOK emoji of a ", "")
    |> String.replace("A TOK emoji of an ", "")
    |> String.split(" ")
    |> Enum.join("-")
    |> String.replace("--", "-")
  end
end
