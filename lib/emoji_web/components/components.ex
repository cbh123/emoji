defmodule EmojiWeb.Components do
  use EmojiWeb, :html

  attr :id, :string, required: true
  attr :class, :string, default: nil
  attr :prediction, :map, required: true

  def emoji(assigns) do
    ~H"""
    <div class={@class}>
      <.image id={@id} prediction={@prediction} />
      <.feedback id={@id} prediction={@prediction} />
    </div>
    """
  end

  def emoji_no_feedback(assigns) do
    ~H"""
    <.image id={@id} prediction={@prediction} />
    """
  end

  defp image(assigns) do
    ~H"""
    <div class="group aspect-h-10 aspect-w-10 block overflow-hidden rounded-lg bg-gray-100 focus-within:ring-2 focus-within:ring-black-500 focus-within:ring-offset-2 focus-within:ring-offset-gray-100">
         <%= if is_nil(@prediction.emoji_output) and is_nil(@prediction.no_bg_output) do %>
           <div class="flex items-center justify-center h-36">
             <p class="animate-pulse ">Loading...</p>
           </div>
         <% else %>
           <button
             id={"prediction-#{@id}-btn"}
             phx-hook="DownloadImage"
             phx-value-name={@prediction.prompt |> humanize()}
             phx-value-image={@prediction.no_bg_output || @prediction.emoji_output}
             type="button"
           >
             <img
               src={@prediction.no_bg_output || @prediction.emoji_output}
               alt={@prediction.prompt}
               class="pointer-events-none object-cover group-hover:opacity-75"
             />
           </button>
         <% end %>
      </div>
    <.link
      navigate={~p"/emoji/#{@prediction.id}"}
      class="mt-2 block truncate text-sm font-medium text-gray-900"
    >
      :<%= humanize(@prediction.prompt) %>:
    </.link>
    """
  end

  defp feedback(assigns) do
    ~H"""
    <div class={"flex justify-between items-center feedback-#{@prediction.id}"}>
         <button
           id={"thumbs-up-#{@prediction.id}"}
           phx-click={JS.hide(to: ".feedback-#{@prediction.id}") |> JS.push("thumbs-up")}
           phx-value-id={@prediction.id}
           class="rounded-full bg-gray-50 border p-1 mt-2"
         >
           <img
             class="h-6"
             src="https://github.com/replicate/zoo/assets/14149230/866884cd-071e-435f-8e35-8e8754c97da0"
             alt=""
           />
         </button>
         <button
           id={"thumbs-down-#{@prediction.id}"}
           phx-value-id={@prediction.id}
           phx-click={JS.hide(to: ".feedback-#{@prediction.id}") |> JS.push("thumbs-down")}
           class="rounded-full bg-gray-50 border p-1 mt-2 rotate-180"
         >
           <img
             class="h-6"
             src="https://github.com/replicate/zoo/assets/14149230/866884cd-071e-435f-8e35-8e8754c97da0"
             alt=""
           />
         </button>
      </div>
    """
  end

  defp humanize(name) do
    Emoji.Utils.humanize(name)
  end
end
