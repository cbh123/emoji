defmodule Emoji.Embeddings do
  @moduledoc """
  Business logic for embeddings.
  """

  @doc """
  Creates an embedding and returns it in binary form.
  """
  def create(
        text,
        embeddings_model \\ "daanelson/imagebind:0383f62e173dc821ec52663ed22a076d9c970549c209666ac3db181618b7a304"
      ) do
    embeddings_model
    |> Replicate.run(text_input: text, modality: "text")
    |> Nx.tensor()
    |> Nx.to_binary()
  end

  def clean(text) do
    text
    |> String.replace("A TOK emoji of a", "")
    |> String.trim()
  end

  def search_emojis(query) do
    embedding = create(query) |> Nx.from_binary(:f32)

    %{labels: labels} = Emoji.Embeddings.Index.search(embedding, 10)

    labels
    |> Nx.to_flat_list()
    |> Emoji.Predictions.get_predictions()
  end
end
