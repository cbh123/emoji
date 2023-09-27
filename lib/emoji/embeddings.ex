defmodule Emoji.Embeddings do
  @moduledoc """
  Business logic for embeddings.
  """

  @doc """
  Creates an embedding and returns it in binary form.
  """
  def create(text, embeddings_model) do
    embeddings_model
    |> Replicate.run(text_input: text, modality: "text")
    |> Nx.tensor()
    |> Nx.to_binary()
  end

  @doc """
  Creates an image embedding given an image url and returns it in binary form.
  """
  def create_image(image_url, embeddings_model) do
    image_uri =
      image_url |> Req.get!() |> Map.get(:body) |> binary_to_data_uri("image/png")

    embeddings_model
    |> Replicate.run(input: image_uri, modality: "vision")
    |> Nx.tensor()
    |> Nx.to_binary()
  end

  def clean(text) do
    text
    |> String.replace("A TOK emoji of a", "")
    |> String.trim()
  end

  defp binary_to_data_uri(binary, mime_type) do
    base64 = Base.encode64(binary)
    "data:#{mime_type};base64,#{base64}"
  end

  def search_emojis(query, num_results \\ 9) do
    embedding =
      create(
        query,
        "daanelson/imagebind:0383f62e173dc821ec52663ed22a076d9c970549c209666ac3db181618b7a304"
      )
      |> Nx.from_binary(:f32)

    %{labels: labels, distances: distances} =
      Emoji.Embeddings.Index.search(embedding, num_results)

    ids = Nx.to_flat_list(labels)
    distances = Nx.to_flat_list(distances)

    Enum.zip_with(ids, distances, fn id, distance ->
      prediction = Emoji.Predictions.get_prediction!(id)
      {prediction, distance}
    end)
    |> Enum.sort_by(fn {_prediction, distance} -> distance end)
  end
end
