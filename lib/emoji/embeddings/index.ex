defmodule Emoji.Embeddings.Index do
  @moduledoc """
  Index for embedding search.
  """
  use GenServer
  import Logger
  @me __MODULE__

  def start_link(_opts) do
    GenServer.start_link(@me, [], name: @me)
  end

  def init(_args) do
    {:ok, index} = HNSWLib.Index.new(:l2, 1024, 100_000)

    Emoji.Predictions.list_predictions()
    |> Enum.reduce(index, fn prediction, index ->
      id = prediction.id
      embedding = prediction.embedding

      HNSWLib.Index.add_items(index, Nx.from_binary(embedding, :f32), ids: Nx.tensor([id]))
      index
    end)

    Logger.info("Index successfully created")
    {:ok, index}
  end

  def add(id, embedding) do
    GenServer.cast(@me, {:add, id, embedding})
  end

  def search(embedding, k) do
    GenServer.call(@me, {:search, embedding, k})
  end

  def handle_cast({:add, id, embedding}, index) do
    HNSWLib.Index.add_items(index, Nx.from_binary(embedding, :f32), ids: Nx.tensor([id]))
    index
    {:noreply, index}
  end

  def handle_call({:search, embedding, k}, _from, index) do
    {:ok, labels, dists} = HNSWLib.Index.knn_query(index, embedding, k: k)
    {:reply, %{labels: labels, distances: dists}, index}
  end

  def terminate(reason, _state) do
    Logger.error("#{__MODULE__} terminated due to #{inspect(reason)}")
  end
end
