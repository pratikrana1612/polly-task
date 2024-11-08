defmodule PollyWeb.PollLive.Show do
  use PollyWeb, :live_view

  alias Polly.VoteManager
  alias Polly.Polls
  alias Polly.PollsManager

  alias PollyWeb.PollyComponents

  @polls_topic Polly.Constants.encode(:polls_topic)
  @poll_vote_event Polly.Constants.encode(:new_vote_event)

  @impl true
  def mount(_params, _session, socket) do
    PollyWeb.Endpoint.subscribe(@polls_topic)
    {:ok, socket}
  end

  @impl true
  def handle_params(params, _, socket) do
    {:noreply, apply_action(params, socket.assigns.live_action, socket)}
  end

  defp apply_action(%{"id" => id}, :show, socket) do
    poll = Polls.get_poll(id)

    if is_nil(poll) do
      socket
      |> put_flash(:error, "Poll with the provided id doesn't exist")
      |> push_navigate(to: "/")
    else
      form = to_form(%{"option" => nil})

      {already_voted?, selected_option_id} = fetch_vote_info(socket.assigns.current_user, id)

      socket
      |> assign(:page_title, page_title(socket.assigns.live_action))
      |> assign(:poll, poll)
      |> assign(:form, form)
      |> assign(:already_voted, already_voted?)
      |> assign(:selected_option_id, selected_option_id)
    end
  end

  defp apply_action(%{"id" => id}, :show_result, socket) do
    poll = Polls.get_poll(id, true)

    if is_nil(poll) do
      socket
      |> put_flash(:error, "Poll with the provided id doesn't exist")
      |> push_navigate(to: "/")
    else
      socket
      |> assign(:page_title, page_title(socket.assigns.live_action))
      |> assign(:poll, poll)
    end
  end

  @impl true
  def handle_event("validate", _params, socket) do
    socket =
      if is_nil(socket.assigns.current_user) do
        socket
        |> put_flash(:error, "You need to sign in to vote")
      else
        socket
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("save", %{"option" => option_id} = params, socket) do
    # Check if the user is signed in
    if is_nil(socket.assigns.current_user) do
      socket
      |> put_flash(:error, "You need to sign in to vote")
    else
      # Check if the user has already voted
      if socket.assigns.already_voted do
        socket
        |> put_flash(:error, "You have already voted in this poll")
      else
        # Perform the vote
        increment_vote(socket, params)
        PollyWeb.Endpoint.broadcast_from(self(), @polls_topic, @poll_vote_event, %{})

        socket
        |> assign(:already_voted, true)
        |> assign(:selected_option_id, option_id)
        |> put_flash(:info, "Thank you for voting!")
      end
    end
  end

  @impl true
  def handle_info(%{topic: @polls_topic, event: @poll_vote_event, payload: _state}, socket) do
    if socket.assigns.live_action == :show_result do
      {:noreply, update(socket, :poll, fn poll -> Polls.get_poll(poll.id, true) end)}
    else
      {:noreply, socket}
    end
  end

  defp increment_vote(socket, params) do
    poll_id = socket.assigns.poll.id
    option_id = params["option"]
    PollsManager.incr_vote!(poll_id, option_id)
    VoteManager.add_vote(socket.assigns.current_user, poll_id, option_id)
  end

  defp fetch_vote_info(nil, _poll_id) do
    {false, nil}
  end

  defp fetch_vote_info(username, poll_id) when is_binary(username) do
    VoteManager.fetch_vote(username, poll_id)
  end

  defp page_title(:show), do: "Show Poll"
  defp page_title(:show_result), do: "Show Result"
  defp page_title(:edit), do: "Edit Poll"
end
