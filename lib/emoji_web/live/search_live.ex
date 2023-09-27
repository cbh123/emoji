defmodule EmojiWeb.SearchLive do
  use EmojiWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(
       results: [],
       query: nil,
       loading: false,
       form: to_form(%{"query" => nil, "search_via_images" => false})
     )}
  end

  @impl true
  def handle_event(
        "search",
        %{"query" => query, "search_via_images" => search_via_images},
        socket
      ) do
    {:noreply,
     push_patch(socket,
       to: ~p"/experimental-search?q=#{query}&search_via_images=#{search_via_images}"
     )}
  end

  @impl true
  def handle_params(%{"q" => query}, _uri, socket) do
    Task.async(fn -> Emoji.Embeddings.search_emojis(query, 3, false) end)

    {:noreply,
     socket
     |> assign(
       loading: true,
       form: to_form(%{"query" => query})
     )}
  end

  @impl true
  def handle_params(%{"q" => query, "search_via_images" => search_via_images}, _uri, socket) do
    Task.async(fn -> Emoji.Embeddings.search_emojis(query, 3, search_via_images == "true") end)

    {:noreply,
     socket
     |> assign(
       loading: true,
       form: to_form(%{"query" => query, "search_via_images" => search_via_images})
     )}
  end

  def handle_params(_params, _uri, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_info({ref, results}, socket) do
    Process.demonitor(ref, [:flush])

    {:noreply, socket |> assign(results: results, loading: false)}
  end
end
