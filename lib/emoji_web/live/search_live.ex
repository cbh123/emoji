defmodule EmojiWeb.SearchLive do
  use EmojiWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket |> assign(results: [], query: nil, loading: false)}
  end

  @impl true
  def handle_event("search", %{"query" => query}, socket) do
    {:noreply, push_patch(socket, to: ~p"/experimental-search?q=#{query}")}
  end

  @impl true
  def handle_params(%{"q" => query}, _uri, socket) do
    Task.async(fn -> Emoji.Embeddings.search_emojis(query) end)

    {:noreply, socket |> assign(loading: true) |> assign(query: query)}
  end

  def handle_params(_params, _uri, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_info({ref, results}, socket) do
    Process.demonitor(ref, [:flush])

    {:noreply, socket |> assign(results: results, loading: false)}
  end

  defp humanize(name) do
    Emoji.Utils.humanize(name)
  end
end
