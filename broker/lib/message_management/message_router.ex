defmodule MessageRouter do
  use GenServer

  def start_link(_args) do
    GenServer.start_link(__MODULE__, [], name: :mess_router)
  end

  def init(arg) do
    {:ok, %{producers: [], subscriber: %{}}}
  end

  def handle_cast({:add_subscriber, message}, state) do
    new_subscribers = Map.get(state, :subscriber) |> Map.put(String.to_atom(Map.get(message, "name")), [])
    {:noreply,  %{producers: Map.get(state, :producers), subscriber: new_subscribers }}
  end

  def handle_cast({:add_producer, message}, state) do
    new_producers = Map.get(state, :producers) |> List.insert_at(-1, Map.get(message, "name"))
    {:noreply,  %{producers: new_producers, subscriber: Map.get(state, :subscriber) }}
  end

  def handle_cast({:add_subscription, message}, state) do
    name = String.to_atom(Map.get(message, "name"))
    subscription = Map.get(message, "to")
    consumer_subscriptions = Map.get(state, :subscriber) |> Map.get(name) |>List.insert_at(-1, subscription)
    new_subscribers = Map.get(state, :subscriber) |> Map.put(name, consumer_subscriptions)
    GenServer.cast(name,{:subscribe, subscription})
    {:noreply,  %{producers: Map.get(state, :producers), subscriber: new_subscribers }}
  end

  def handle_cast({:delete_subscription, message}, state) do
    name = String.to_atom(Map.get(message, "name"))
    subscription = Map.get(message, "to")
    GenServer.cast(name,{:unsubscribe, subscription})
    {:noreply,  %{producers: Map.get(state, :producers), subscriber: Map.get(state, :subscriber) }}
  end

  def handle_cast({:publish, message}, state) do
    if(verify_message(message)) do
      publish_message_to_all(Map.get(state, :subscriber), message)
      GenServer.cast(:mess_cacher, {:add_message, message})
    else
      GenServer.cast(:dead_letter, message)
    end
    {:noreply, state}
  end

  def publish_message_to_all(subscription_list, message) do
    for {client, lst} <- subscription_list do
      if((Atom.to_string(client)!= Map.get(message, "producer")) && (Enum.member?(lst, Map.get(message, "topic")) || Enum.member?(lst, Map.get(message, "producer")))) do
        IO.puts("Sending message to #{client}")
        GenServer.cast(client, {:publish, message})
      end
    end
  end

  def verify_message(message) do
    if(Map.get(message, "producer")!= nil && Map.get(message, "topic") != nil && Map.get(message, "id") != nil && Map.get(message, "content") != nil) do
      true
    else
      false
    end
  end
end
