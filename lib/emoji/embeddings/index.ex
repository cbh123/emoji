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
    index = ExFaiss.Index.new(1024, "IDMap,Flat")

    Emoji.Predictions.list_predictions()
    |> Enum.reduce(index, fn prediction, index ->
      id = prediction.id
      embedding = prediction.embedding

      ExFaiss.Index.add_with_ids(index, Nx.from_binary(embedding, :f32), Nx.tensor([id]))
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
    index = ExFaiss.Index.add_with_ids(index, embedding, id)
    {:noreply, index}
  end

  def handle_call({:search, embedding, k}, _from, index) do
    results = ExFaiss.Index.search(index, embedding, k)
    {:reply, results, index}
  end

  def terminate(reason, _state) do
    Logger.error("#{__MODULE__} terminated due to #{inspect(reason)}")
  end
end
