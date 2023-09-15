defmodule EmojiWeb.SearchLive do
  use EmojiWeb, :live_view
  alias Emoji.Predictions

  def mount(_params, _session, socket) do
    {:ok, socket |> assign(results: [])}
  end

  def handle_event("search", %{"query" => query}, socket) do
    {:noreply, push_patch(socket, to: ~p"/experimental-search?q=#{query}")}
  end

  @impl true
  def handle_params(%{"q" => query}, _uri, socket) do
    results = Emoji.Embeddings.search_emojis(query)

    {:noreply, assign(socket, :results, results)}
  end

  def handle_params(_params, _uri, socket) do
    {:noreply, socket}
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
