defmodule TcpSubscriberClient do
  use GenServer

  def start_link(args) do
    IO.puts("#{args} starting")
    {_, socket} = List.first(:ets.lookup(:app, :sub_socket))
    {:ok, client} = :gen_tcp.accept(socket)
    :gen_tcp.send(client, "introduce/q\n")
    m = Poison.decode!(read_message(client, ""))
    IO.inspect(m)
    name = Map.get(m, "name")
    IO.puts("#{args} connected to #{name}")
    GenServer.start_link(__MODULE__, %{socket: client, subscriptions: %{}, message_queue: []}, name: String.to_atom(name))
  end


  def init(args) do
    IO.puts("Ready to send messages to client")
    t = :timer.send_after(10000, :retry_messages)
    {:ok, args}
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
        :ok
    end
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
    queue = Map.get(state, :message_queue) |> List.insert_at(-1, message)
    queue = if(Map.get(s, Map.get(message, "topic"), false) || Map.get(s, Map.get(message, "producer"), false)) do
              r = try_send_message(Map.get(state, :socket), message, 0)
              if(r) do
                List.delete(queue, message)
              else
                queue
              end
            else
              queue
            end
    {:noreply, %{socket: Map.get(state, :socket), subscriptions: Map.get(state, :subscriptions), message_queue: queue}}
  end

  def try_send_message(socket, message, trial) do
    IO.puts("trying to send message")
    if(trial < 4) do
      send_message(socket, message)
      resp = read_message(socket, "")
      if(String.contains?(resp, "received")) do
        GenServer.cast(:mess_cacher, {:delete_message, message})
        true
      else
        try_send_message(socket, message, trial + 1)
      end
    else
      false
    end

  end

  def send_message(socket, message) do
   m = Poison.encode!(message)
   :gen_tcp.send(socket, m <>"/q\n")
  end

  def handle_info(:retry_messages, state) do
    queue = Map.get(state, :message_queue)
    s = Map.get(state, :subscriptions)
    new_queue = for mes <- queue do
                  if(Map.get(s, Map.get(mes, "topic"), false) || Map.get(s, Map.get(mes, "producer"), false)) do
                    r = try_send_message(Map.get(state, :socket), mes, 0)
                    if(r) do
                      nil
                    else
                      mes
                    end
                  else
                    mes
                  end
                end
    new_queue = Enum.filter(new_queue, &!is_nil(&1))
    IO.puts("Retry Message round. Was #{length(queue)}, is #{length(new_queue)}")
    t = :timer.send_after(10000, :retry_messages)
    {:noreply, %{socket:  Map.get(state, :socket), subscriptions: Map.get(state, :subscriptions), message_queue: new_queue}}
  end



end
