defmodule MqttSubscriberClient do
  use GenServer

  def start_link(args) do
    IO.puts("#{args} starting")
    {_, socket} = List.first(:ets.lookup(:app, :mqtt_socket))
    {:ok, client} = :gen_tcp.accept(socket)
    :gen_tcp.send(client, "introduce/q\n")
    m = read_message(client, "") |> Poison.decode!()
    name = Map.get(m, "name")
    IO.puts("#{args} connected to #{name}")
    Task.start_link(fn -> serve(client, String.to_atom(name) ) end)
    GenServer.start_link(__MODULE__, %{socket: client, subscriptions: %{}, message_queue: %{}}, name: String.to_atom(name))
  end

  defp read_message(socket, message) do
    case :gen_tcp.recv(socket, 0) do
    {:ok, data} ->
      if (String.contains?(data, "/q")) do
        String.replace(data, "/q", "")
      else
        read_message(socket, message <> data)
      end
      {:error, _} ->
        ""
    end
  end

  def init(args) do
    IO.puts("Ready to send messages to client")
    t = :timer.send_after(10000, :retry_messages)
    {:ok, args}
  end


  defp acknowledge(line, socket) do
    _r = :gen_tcp.send(socket, line <>"/q\n")
  end

  defp serve(socket, name) do
    message = read_message(socket, "")
    message =  Poison.decode!(message)
    evaluate_message(message, socket, name)
    serve(socket, name)
  end

  def evaluate_message(message, socket, name) do
    # IO.inspect(message)
    case Map.get(message, "type") do
      "PUBREL" ->  GenServer.cast(:mess_cacher, {:delete_message, message})
                   acknowledge(Poison.encode!(%{type: "PUBCOMP", id: Map.get(message, "id")}), socket)
      "received"-> GenServer.cast(:mess_cacher, {:delete_message, message})
                   GenServer.cast(name, {:delete_from_queue, Map.get(message, "id")})
             m -> GenServer.cast(:mess_router, {:publish, message})
                  acknowledge(Poison.encode!(%{type: "PUBREC", id: Map.get(message, "id")}), socket)
    end
  end

  def handle_cast({:delete_from_queue, id}, state) do
    new_queue = Map.get(state, :message_queue) |> Map.delete(id)

    {:noreply, %{socket:  Map.get(state, :socket), subscriptions: Map.get(state, :subscriptions), message_queue: new_queue}}
  end


  def handle_cast({:subscribe, to}, state) do
    if(Map.has_key?(Map.get(state, :subscriptions), to)) do
      t = :timer.send_after(10000, :retry_messages)
    end
    new_subscriptions = Map.get(state, :subscriptions) |> Map.put(to, true)
    IO.puts("New subscription")
    IO.inspect(new_subscriptions)

    {:noreply, %{socket:  Map.get(state, :socket), subscriptions: new_subscriptions, message_queue: Map.get(state, :message_queue)}}

  end

  def handle_cast({:unsubscribe, to}, state) do
    new_subscriptions = Map.get(state, :subscriptions) |> Map.put(to, false)
    IO.puts("Unsubscription")
    IO.inspect(new_subscriptions)

    {:noreply, %{socket:  Map.get(state, :socket), subscriptions: new_subscriptions, message_queue: Map.get(state, :message_queue)}}

  end

  def handle_cast({:publish, message}, state) do
    IO.puts("Message received")
    s = Map.get(state, :subscriptions)
    queue = Map.get(state, :message_queue) |> Map.put(Map.get(message, "id"), message)
    if(Map.get(s, Map.get(message, "topic"), false) || Map.get(s, Map.get(message, "producer"), false)) do
      send_message(Map.get(state, :socket), message)
    end
    {:noreply, %{socket: Map.get(state, :socket), subscriptions: Map.get(state, :subscriptions), message_queue: queue}}
  end


  def send_message(socket, message) do
   m = Poison.encode!(message)
   :gen_tcp.send(socket, m <>"/q\n")
  end

  def handle_info(:retry_messages, state) do
    queue = Map.get(state, :message_queue)
    s = Map.get(state, :subscriptions)
    for mes <- Map.values(queue) do
      if(Map.get(s, Map.get(mes, "topic"), false) || Map.get(s, Map.get(mes, "producer"), false)) do
        send_message(Map.get(state, :socket), mes)
      end
    end
    t = :timer.send_after(10000, :retry_messages)
    {:noreply, %{socket:  Map.get(state, :socket), subscriptions: Map.get(state, :subscriptions), message_queue: queue}}
  end



end
