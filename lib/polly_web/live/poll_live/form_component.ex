defmodule PollyWeb.PollLive.FormComponent do
  use PollyWeb, :live_component

  alias Polly.Polls
  alias Polly.Schema.Poll

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Create a New Poll</:subtitle>
      </.header>
      
      <.simple_form
        for={@form}
        id="poll-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:title]} type="text" label="Poll Title" required />
        <.input field={@form[:description]} type="textarea" label="Description" />
        <div>
          <%= for {option, index} <- Enum.with_index(@form.data.options || []) do %>
            <.input field={option.text} type="text" label={"Option #{index + 1}"} required />
            <button
              type="button"
              phx-click="delete-option"
              phx-value-index={index}
              phx-target={@myself}
            >
              Delete Option
            </button>
          <% end %>
           <button type="button" phx-click="add-option" phx-target={@myself}>Add Option</button>
        </div>
        
        <:actions>
          <.button phx-disable-with="Saving...">Save Poll</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  @impl true
  def update(%{poll: poll} = assigns, socket) do
    changeset = Polls.change_poll(poll)
    {:ok, assign(socket, assigns) |> assign(:changeset, changeset) |> assign_form(changeset)}
  end

  def handle_event("add-option", _, socket) do
    socket =
      update(socket, :changeset, fn changeset ->
        existing = Ecto.Changeset.get_field(changeset, :options, [])
        Ecto.Changeset.put_embed(changeset, :options, existing ++ [%{}])
      end)

    socket = assign(socket, :form, to_form(socket.assigns.changeset))

    {:noreply, socket}
  end

  def handle_event("delete-option", %{"index" => index}, socket) do
    socket =
      update(socket, :changeset, fn changeset ->
        options = Ecto.Changeset.get_field(changeset, :options, [])
        updated_options = List.delete_at(options, String.to_integer(index))
        Ecto.Changeset.put_embed(changeset, :options, updated_options)
      end)

    socket = assign(socket, :form, to_form(socket.assigns.changeset))

    {:noreply, socket}
  end

  # @impl true
  # def handle_event("validate", %{"poll" => poll_params}, socket) do
  #   changeset =
  #     socket.assigns.poll
  #     |> Polls.change_poll(poll_params)
  #     |> Map.put(:action, :validate)

  #   {:noreply, assign(socket, :form, to_form(changeset))}
  # end

  def handle_event("validate", %{"poll" => poll_params}, socket) do
    changeset = Polly.Polls.change_poll(socket.assigns.poll, poll_params)
    {:noreply, assign(socket, changeset: changeset)}
  end

  def handle_event("save", %{"poll" => poll_params}, socket) do
    save_poll(socket, socket.assigns.action, poll_params)
  end

  defp save_poll(socket, :new, poll_params) do
    poll_params = Map.put(poll_params, "creator_username", socket.assigns.current_user.username)

    case Polls.create_poll(poll_params) do
      {:ok, poll} ->
        notify_parent({:saved, poll})
        {:noreply, push_patch(socket, to: "/")}

      {:error, changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_poll(socket, :edit, poll_params) do
    case Polls.update_poll(socket.assigns.poll, poll_params) do
      {:ok, poll} ->
        notify_parent({:saved, poll})
        {:noreply, push_patch(socket, to: "/")}

      {:error, changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, changeset) do
    assign(socket, :form, to_form(changeset))
  end

  def mount(_params, _session, socket) do
    changeset = Polly.Polls.change_poll(%Polly.Schema.Poll{})
    {:ok, assign(socket, changeset: changeset)}
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
