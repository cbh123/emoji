defmodule EmojiWeb.HomeLive do
  use EmojiWeb, :live_view
  alias Emoji.Predictions

  @preprompt "A TOK emoji of a "

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(form: to_form(%{"prompt" => ""}))
     |> stream(:predictions, Predictions.list_finished_predictions() |> Enum.reverse())
     |> stream(:recent_predictions, Predictions.list_firehose_predictions())}
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

  def handle_event("validate", %{"prompt" => _prompt}, socket) do
    {:noreply, socket}
  end

  def handle_event("save", %{"prompt" => prompt}, socket) do
    styled_prompt =
      (@preprompt <> String.trim_trailing(prompt))
      |> String.replace("emoji of a a ", "emoji of a ")
      |> String.replace("emoji of a an ", "emoji of an ")

    {:ok, prediction} = Predictions.create_prediction(%{prompt: styled_prompt})

    start_task(fn -> {:image_generated, prediction.id, gen_image(styled_prompt)} end)

    {:noreply,
     socket
     |> stream_insert(:predictions, prediction, at: 0)}
  end

  def handle_info({:image_generated, id, image}, socket) do
    {:ok, prediction} = update_prediction(id, image)

    start_task(fn -> {:background_removed, id, remove_bg(image)} end)

    {:noreply,
     socket
     |> stream_insert(:predictions, prediction)
     |> put_flash(:info, "Image generated. Starting background removal")}
  end

  def handle_info({:background_removed, id, image}, socket) do
    {:ok, prediction} = update_prediction(id, image)

    {:noreply,
     socket
     |> stream_insert(:predictions, prediction)
     |> put_flash(:info, "Background successfully removed!")}
  end

  defp human_name(name) do
    dasherize(name)
  end

  defp dasherize(name) do
    name
    |> String.replace(@preprompt, "")
    |> String.replace("A TOK emoji of an ", "")
    |> String.split(" ")
    |> Enum.join("-")
    |> String.replace("--", "-")
  end

  defp remove_bg(url) do
    "cjwbw/rembg:fb8af171cfa1616ddcf1242c093f9c46bcada5ad4cf6f2fbe8b81b330ec5c003"
    |> Replicate.run(image: url)
  end

  defp gen_image(prompt) do
    "fofr/sdxl-emoji:4d2c2e5e40a5cad182e5729b49a08247c22a5954ae20356592caaada42dc8985"
    |> Replicate.run(prompt: prompt, width: 768, height: 768, num_inference_steps: 30)
    |> List.first()
  end

  defp update_prediction(id, image) do
    id
    |> Predictions.get_prediction!()
    |> Predictions.update_prediction(%{output: image})
  end

  defp start_task(fun) do
    pid = self()

    Task.start_link(fn ->
      result = fun.()
      send(pid, result)
    end)
  end
end
