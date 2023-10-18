defmodule EmojiWeb.SlackController do
  use EmojiWeb, :controller

  def command(conn, params) do
    # Modify based on the structure of your response
    {:ok, body} = send_message("⏳ Generating...", params["channel_id"])

    Task.async(fn -> process_request(params, body["message"]["ts"]) end)

    send_resp(conn, 200, "")
  end

  defp process_request(params, message_ts) do
    {:ok, prediction} = gen_image(params["text"])

    image = prediction.output |> List.first()

    {:ok, %{status_code: 200}} =
      update_slack_message(params["channel_id"], message_ts, "🖌️ Removing background...")

    image = remove_bg(image)

    {:ok, %{status_code: 200}} =
      update_slack_message(params["channel_id"], message_ts, image, params["text"])
  end

  defp update_slack_message(channel_id, timestamp, text) do
    url = "https://slack.com/api/chat.update"

    headers = [
      {"Authorization", "Bearer #{System.fetch_env!("SLACK_API_TOKEN")}"},
      {"Content-type", "application/json"}
    ]

    payload = %{
      "channel" => channel_id,
      # This ensures the correct message is updated
      "ts" => timestamp,
      "text" => text
    }

    HTTPoison.post(url, Jason.encode!(payload), headers)
  end

  defp update_slack_message(channel_id, timestamp, image, text) do
    url = "https://slack.com/api/chat.update"

    headers = [
      {"Authorization", "Bearer #{System.fetch_env!("SLACK_API_TOKEN")}"},
      {"Content-type", "application/json"}
    ]

    payload = %{
      "channel" => channel_id,
      # This ensures the correct message is updated
      "ts" => timestamp,
      "text" => text,
      "blocks" => [
        %{
          type: "image",
          title: %{
            type: "plain_text",
            text: text
          },
          block_id: "image4",
          image_url: image,
          alt_text: text
        }
      ]
    }

    HTTPoison.post(url, Jason.encode!(payload), headers)
  end

  defp send_message(message, channel_id) do
    url = "https://slack.com/api/chat.postMessage"

    headers = [
      {"Authorization", "Bearer #{System.fetch_env!("SLACK_API_TOKEN")}"},
      {"Content-type", "application/json"}
    ]

    payload = %{
      # You can also get this from the initial request params
      "channel" => channel_id,
      "text" => message
    }

    {:ok, %{status_code: 200} = response} = HTTPoison.post(url, Jason.encode!(payload), headers)
    {:ok, Jason.decode!(response.body)}
  end

  defp gen_image(prompt) do
    {:ok, deployment} = Replicate.Deployments.get("cbh123/sdxl-emoji")

    {:ok, prediction} =
      Replicate.Deployments.create_prediction(deployment,
        prompt: prompt,
        width: 512,
        height: 512,
        num_inference_steps: 30,
        negative_prompt: "racist, xenophobic, antisemitic, islamophobic, bigoted"
      )
      |> wait()

    {:ok, prediction}
  end

  defp wait({:ok, prediction}), do: Replicate.Predictions.wait(prediction)

  defp remove_bg(url) do
    "cjwbw/rembg:fb8af171cfa1616ddcf1242c093f9c46bcada5ad4cf6f2fbe8b81b330ec5c003"
    |> Replicate.run(image: url)
  end
end
